#!/bin/bash
. utils/logging.sh
. utils/check-dependencies.sh
. utils/kubectl.sh
. utils/trafgen.sh

##
#   Help function
##
function display_usage() {
    echo "Kites is a plugin of kubernetes-playground."
    echo "This script must be run on the master node."
    echo -e "\nUsage: $0 --cni <cni conf. name> [Optional arguments] \n"
    echo "Mandatory arguments:"
    echo "  --cni               : set the name of the CNI configuration ex: weavenet, calicoIPIP, calicoVXLAN, flannel"
    echo "Optional arguments:"
    echo "  --nodes             : set the number of nodes in the cluster. Default set =2"
    echo "  --repeat | -r       : set the number of run. Default set =1"
    echo "  --test-type | -t    : set the test-type between: all, tcp, udp. Default set =all"
    echo "  --conf              : set the configuration between: all, samepod, samenode, diffnode. Default set =all"
    echo "  --clean-all         : remove all experiment data and pods already created (need namespace)."
    echo "  --namespace | -n    : set the namespace name. Default set =kites"
    echo "  --nocpu | -nc       : do not execute CPU monitoing."
    echo "  -4                  : use IPv4 only. Default."
    echo "  -6                  : use IPv6 only."
    echo "  --bytes | -b        : set a list comma separated of bytes. Example: 100,1000. Default 100."
    echo "  -h                  : display this help message"
}

[ "$1" = "" ] && display_usage && exit

##
#   Default parameters
##

declare -xg KITES_HOME="/vagrant/ext/kites"
declare -xg KITES_NAMSPACE_NAME="kites"

N=2
RUN_TEST_TCP="true"
RUN_TEST_UDP="true"
RUN_TEST_SAME="true"
RUN_TEST_SAMENODE="true"
RUN_TEST_DIFF="true"
RUN_CONFIG=("samepod" "samenode" "diffnode")
declare -A RUN_CONFIG_CODE=([samepod]=0 [samenode]=1 [diffnode]=2)
RUN_TEST_CPU="true"
CLEAN_ALL="false"
RUN_IPV4_ONLY="true"
RUN_IPV6_ONLY="false"
PKT_BYTES=(100)
PPS_MIN=10000
PPS_MAX=20000
PPS_INC=10000
export PPS_MIN PPS_MAX PPS_INC
repeatable="false"
monitoing="false"
EXP_N=0
VERBOSITY_LEVEL=5 # default debug level. see in utils/logging.sh

##
#   Import utility functions
##

. cpu-monitoring.sh

##
#   Define utility functions
##



function prometheus_monitoring() {
	log_inf "Start Prometheus monitoring configuration"

	log_inf "Creation of \"monitoring\" namespace"
    kubectl create namespace monitoring
    kubectl apply -f ${KITES_HOME}/prometheus/configmap.yaml
    kubectl apply -f ${KITES_HOME}/prometheus/deployment.yaml
    kubectl apply -f ${KITES_HOME}/prometheus/role-config.yaml
    log_inf "Creation of \"monitoring\" node-exporter-daemonset"
    kubectl apply -f ${KITES_HOME}/prometheus/node-exporter-ds.yaml
    log_inf "Creation of Grafana configuration"
    kubectl apply -f ${KITES_HOME}/prometheus/grafana-config.yaml
    kubectl apply -f ${KITES_HOME}/prometheus/grafana-depl.yaml
    log_inf "Wait until all pods are running."
    kubectl wait -n monitoring --for=condition=Ready pods --all --timeout=600s
}

function create_name_space() {
    log_inf "Create a namespace if not exist."
    CURRENT_NS=$(kubectl get namespaces -o json | jq -r ".items[].metadata.name" | grep ${KITES_NAMSPACE_NAME})

    if [ "$CURRENT_NS" = "" ]; then
        log_debug "Namespace ${KITES_NAMSPACE_NAME} doesn't exists."
        log_debug "Creating: namespace ${KITES_NAMSPACE_NAME}."
        kubectl create namespace ${KITES_NAMSPACE_NAME}
    fi
}

function clean_pod_shared_dir() {
    log_inf "Clean dir. ${KITES_HOME}/pod-shared/"
    shopt -s extglob
    GLOBIGNORE='*.gitignore'
    if [ -d "${KITES_HOME}/pod-shared/" ]; then
        cd "${KITES_HOME}/pod-shared/" || {
            log_error "Failure"
            exit 1
        }
        rm -rf *
        log_debug "Removed all file inside ${KITES_HOME}/pod-shared/"
    fi
    shopt -u extglob
}

function clean_cpu_monitoring_dir() {
    log_inf "Clean dir. ${KITES_HOME}/cpu/"
    shopt -s extglob
    GLOBIGNORE='*.gitignore'
    if [ -d "${KITES_HOME}/cpu/" ]; then
        cd "${KITES_HOME}/cpu/" || {
            log_error "Failure"
            exit 1
        }
        rm -rf *
        log_debug "Removed all file inside ${KITES_HOME}/cpu/"
    fi
    shopt -u extglob
}

function clean_all() {
    log_inf "Clean all environment from data and pods."
    log_debug "Delete daemonset  net-test-ds"
    kubectl delete daemonset net-test-ds -n ${KITES_NAMSPACE_NAME}
    log_debug "Delete pods net-test-single-pod"
    kubectl delete pods net-test-single-pod -n ${KITES_NAMSPACE_NAME}
    clean_pod_shared_dir
    clean_cpu_monitoring_dir
}

function create_pod_list() {
    if [ ! -d "${KITES_HOME}/pod-shared/" ]; then
        log_debug "Directory ${KITES_HOME}/pod-shared/ doesn't exists."
        log_debug "Creating: Directory ${KITES_HOME}/pod-shared/"
        mkdir -p ${KITES_HOME}/pod-shared/
    fi
    kubectl get pod -n ${KITES_NAMSPACE_NAME} -o wide >${KITES_HOME}/pod-shared/podList.txt
    awk '{ print $1, $6, $7}' ${KITES_HOME}/pod-shared/podList.txt >${KITES_HOME}/pod-shared/podNameAndIP.txt
}

function initialize_pods() {
    log_inf "Initialize pods."
    RUN_TEST_SAMENODE=$1
    #creazione daemonset
    log_debug "Create demonset."
    kubectl apply -n ${KITES_NAMSPACE_NAME} -f ${KITES_HOME}/kubernetes/net-test-dev_ds.yaml
    if $RUN_TEST_SAMENODE; then
        log_debug "Create single-pod."
        kubectl apply -n ${KITES_NAMSPACE_NAME} -f ${KITES_HOME}/kubernetes/net-test-single-pod.yaml
    fi
    log_inf "Wait until all pods are running."
    kubectl wait -n ${KITES_NAMSPACE_NAME} --for=condition=Ready pods --all --timeout=600s
}

function get_pods_info() {
    log_inf "Get pods infos."
    log_debug "Obtaining the names, IPs, MAC Address of the DaemonSet."
    pod_index=1
    node_index=1
    echo "" >${KITES_HOME}/pod-shared/pods_nodes.env
    for row in $(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test" -o json | jq -r ".items[] | @base64"); do
        # most of the info are available from here
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }

        log_debug "Obtaining pod name. pod number $pod_index."
        declare -xg "POD_NAME_$pod_index=$(_jq '.metadata.name')"
        declare pod_name=POD_NAME_$pod_index
        echo "POD_NAME_$pod_index=${!pod_name}" >>${KITES_HOME}/pod-shared/pods_nodes.env

        log_debug "Obtaining pod IPv4. pod number $pod_index."
        declare -xg "POD_IP_$pod_index=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test" -o json | jq -r ".items[$pod_index-1].status.podIPs[0].ip")"
        declare ip_name=POD_IP_$pod_index
        echo "${!ip_name}"
        echo "POD_IP_$pod_index=${!ip_name}" >>${KITES_HOME}/pod-shared/pods_nodes.env
        ip_parsed_pods=$(sed -e "s/\./, /g" <<<${!ip_name})
        declare -xg "IP_$pod_index= $ip_parsed_pods"

        if [ "$RUN_IPV6_ONLY" == "true" ]; then
            log_debug "Obtaining pod IPv6. pod number $pod_index."
            declare -xg "POD_IP6_$pod_index=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test" -o json | jq -r ".items[$pod_index-1].status.podIPs[1].ip")"
            declare ip6_name=POD_IP6_$pod_index
            echo "POD_IP6_$pod_index=${!ip6_name}" >>${KITES_HOME}/pod-shared/pods_nodes.env
        fi
        log_debug "Obtaining pod nodeName. pod number $pod_index."
        declare -xg "POD_HOSTNAME_$pod_index=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test" -o json | jq -r ".items[$pod_index-1].spec.nodeName")"
        declare pod_hostname=POD_HOSTNAME_$pod_index
        echo "POD_HOSTNAME_$pod_index=${!pod_hostname}" >>${KITES_HOME}/pod-shared/pods_nodes.env
        log_debug "Obtaining pod MAC. pod number $pod_index."
        declare pod_name=POD_NAME_$pod_index
        mac_pod=$(kubectl -n ${KITES_NAMSPACE_NAME} exec -i "${!pod_name}" -- bash -c "${KITES_HOME}/scripts/linux/get-mac-address-pod.sh")
        declare -xg "MAC_ADDR_POD_$pod_index=$mac_pod"
        #echo "MAC_ADDR_POD_$pod_index=$mac_pod">> ${KITES_HOME}/pod-shared/pods_nodes.env
        log_debug "Name: ${!pod_name}, IPv4: ${!ip_name}, MAC: $mac_pod"
        ((pod_index++))
    done

    if $RUN_TEST_SAMENODE; then
        log_debug "Obtaining the names, IPs, MAC Addresse of the SinglePOD."
        declare -xg "SINGLE_POD_NAME=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test-single-pod" -o jsonpath="{.items[0].metadata.name}")"
        echo "SINGLE_POD_NAME=$SINGLE_POD_NAME" >>${KITES_HOME}/pod-shared/pods_nodes.env
        declare -xg "MAC_ADDR_SINGLE_POD=$(kubectl exec -n ${KITES_NAMSPACE_NAME} -i "$SINGLE_POD_NAME" -- bash -c "${KITES_HOME}/scripts/linux/get-mac-address-pod.sh")"
        #echo "MAC_ADDR_SINGLE_POD="$MAC_ADDR_SINGLE_POD"">> ${KITES_HOME}/pod-shared/pods_nodes.env
        declare -xg "SINGLE_POD_IP=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test-single-pod" -o jsonpath="{.items[0].status.podIPs[0].ip}")"
        echo "SINGLE_POD_IP=$SINGLE_POD_IP" >>"${KITES_HOME}/pod-shared/pods_nodes.env"
        declare -xg "IP_PARSED_SINGLE_POD=$(sed -e "s/\./, /g" <<<${SINGLE_POD_IP})"
        #echo "IP_PARSED_SINGLE_POD="$IP_PARSED_SINGLE_POD"">> ${KITES_HOME}/pod-shared/pods_nodes.env
        if [ "$RUN_IPV6_ONLY" == "true" ]; then
            declare -xg "SINGLE_POD_IP6=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test-single-pod" -o jsonpath="{.items[0].status.podIPs[1].ip}")"
            echo "SINGLE_POD_IP6=$SINGLE_POD_IP6" >>${KITES_HOME}/pod-shared/pods_nodes.env
        fi
        declare -xg "SINGLE_POD_HOSTNAME=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test-single-pod" -o json | jq -r ".items[0].spec.nodeName")"
        echo "SINGLE_POD_HOSTNAME=$SINGLE_POD_HOSTNAME" >>${KITES_HOME}/pod-shared/pods_nodes.env
    fi

    log_debug "Obtaining the names, IPs, MAC Addresse of  worker nodes."
    for row in $(kubectl get nodes --selector='!node-role.kubernetes.io/master' -o json | jq -r ".items[] | @base64"); do
        _jq() {
            echo "${row}" | base64 --decode | jq -r "${1}"
        }
        log_debug "Obtaining node name. node number $node_index."
        declare -xg "NODE_NAME_$node_index=$(_jq '.metadata.name')"
        declare node_name=NODE_NAME_$node_index
        echo "NODE_NAME_$node_index=${!node_name}" >>"${KITES_HOME}/pod-shared/pods_nodes.env"

        for addr in $(kubectl get nodes ${!node_name} -o json | jq -r ".status.addresses[] | @base64"); do
            _jqa() {
                echo "${addr}" | base64 --decode | jq -r "${1}"
            }
            if [ "$(_jqa '.type')" == "InternalIP" ]; then
                declare -xg "NODE_IP_$node_index=$(_jqa '.address')"
                declare node_ip=NODE_IP_$node_index
                echo "NODE_IP_$node_index=${!node_ip}" >>${KITES_HOME}/pod-shared/pods_nodes.env
            fi
        done

        ((node_index++))
    done

}

function initialize_net_test() {
    log_inf "Initialize net test."
    CNI=$1
    N=$2
    RUN_TEST_UDP=$3
    RUN_TEST_SAME=$4
    RUN_TEST_SAMENODE=$5
    RUN_TEST_DIFF=$6
    shift 6
    PKT_BYTES=("$@")
    initialize_pods "$RUN_TEST_SAMENODE"
    create_pod_list
    get_pods_info
    if $RUN_TEST_UDP; then
        # TODO refactoring this script
        if [ "$RUN_IPV4_ONLY" == "true" ]; then
            declare version="4"
        elif [ "$RUN_IPV6_ONLY" == "true" ]; then
            declare version="6"
        fi

        create_udp_traffic "$CNI" "$N" "$RUN_TEST_SAME" "$RUN_TEST_SAMENODE" "$RUN_TEST_DIFF" "$version" "${PKT_BYTES[@]}"
    fi
}

function exec_tcp_test_between_pods() {
    log_inf "Start execution TCP net test between pods."
    ID_EXP=$1
    N=$2
    RUN_TEST_SAME=$3
    RUN_TEST_SAMENODE=$4
    RUN_TEST_DIFF=$5
    RUN_TEST_CPU=$6
    CPU_TEST="TCP"
    cd "${KITES_HOME}/pod-shared" || {
        log_error "Failure"
        exit 1
    }

    for ((i = 1; i <= $N; i++)); do
        log_debug "POD $i to other PODS..."
        log_debug "----------------------------------------------"
        for ((j = 1; j <= $N; j++)); do
            declare name1_pod="POD_NAME_$i"
            declare name2_pod="POD_NAME_$j"
            if [ "$RUN_IPV4_ONLY" == "true" ]; then
                declare ip1_pod="POD_IP_$i"
                declare ip2_pod="POD_IP_$j"
            elif [ "$RUN_IPV6_ONLY" == "true" ]; then
                declare ip1_pod="POD_IP6_$i"
                declare ip2_pod="POD_IP6_$j"
            fi
            declare host1_pod="POD_HOSTNAME_$i"
            declare host2_pod="POD_HOSTNAME_$j"
            log_debug "host1_pod= ${!host1_pod}    host2_pod= ${!host2_pod}"
            if ([ "$i" -eq "$j" ] && $RUN_TEST_SAME) || ([ "${!host1_pod}" != "${!host2_pod}" ] && $RUN_TEST_DIFF); then
                if $RUN_TEST_CPU; then
                    if [ "$i" -eq "$j" ] && $RUN_TEST_SAME; then
                        start_cpu_monitor_nodes "$N" "samepod" 0 "${!host1_pod//[$' ']/}" $CPU_TEST "no" "POD"
                    elif [ "${!host1_pod}" != "${!host2_pod}" ] && $RUN_TEST_DIFF; then
                        start_cpu_monitor_nodes "$N" "diffnode" 2 "${!host1_pod//[$' ']/}TO${!host2_pod//[$' ']/}" $CPU_TEST "no" "POD"
                    fi
                fi
                kctl_exec ${!name1_pod} "${KITES_HOME}/scripts/linux/iperf-test.sh ${!ip1_pod} ${!ip2_pod} ${!host1_pod} ${!host2_pod} ${!name1_pod} ${!name2_pod} $ID_EXP"
                if $RUN_TEST_CPU; then
                    if [ "$i" -eq "$j" ] && $RUN_TEST_SAME; then
                        stop_cpu_monitor_nodes "$N" "samepod" 0 "${!host1_pod//[$' ']/}" $CPU_TEST "no" "POD"
                    elif [ "${!host1_pod}" != "${!host2_pod}" ] && $RUN_TEST_DIFF; then
                        stop_cpu_monitor_nodes "$N" "diffnode" 2 "${!host1_pod//[$' ']/}TO${!host2_pod//[$' ']/}" $CPU_TEST "no" "POD"
                    fi
                fi
            fi
        done
        if $RUN_TEST_SAMENODE; then
            if [ "$RUN_IPV4_ONLY" == "true" ]; then
                declare single_pod_ip="SINGLE_POD_IP"
            elif [ "$RUN_IPV6_ONLY" == "true" ]; then
                declare single_pod_ip="SINGLE_POD_IP6"
            fi

            if $RUN_TEST_CPU; then
                if ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" = "${!host1_pod//[$' ']/}" ] && $RUN_TEST_SAMENODE); then
                    start_cpu_monitor_nodes "$N" "samenode" 1 "${!host1_pod//[$' ']/}" $CPU_TEST "no" "POD"
                elif ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" != "${!host1_pod//[$' ']/}" ] && $RUN_TEST_DIFF); then
                    start_cpu_monitor_nodes "$N" "diffnode" 2 "${!host1_pod//[$' ']/}TO${SINGLE_POD_HOSTNAME//[$' ']/}" $CPU_TEST "no" "POD"
                fi
            fi
            kctl_exec ${!name1_pod} "${KITES_HOME}/scripts/linux/iperf-test.sh ${!ip1_pod} ${!single_pod_ip} ${!host1_pod} $SINGLE_POD_HOSTNAME ${!name1_pod} $SINGLE_POD_NAME $ID_EXP"
            if $RUN_TEST_CPU; then
                if ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" = "${!host1_pod//[$' ']/}" ] && $RUN_TEST_SAMENODE); then
                    stop_cpu_monitor_nodes "$N" "samenode" 1 "${!host1_pod//[$' ']/}" $CPU_TEST "no" "POD"
                elif ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" != "${!host1_pod//[$' ']/}" ] && $RUN_TEST_DIFF); then
                    stop_cpu_monitor_nodes "$N" "diffnode" 2 "${!host1_pod//[$' ']/}TO${SINGLE_POD_HOSTNAME//[$' ']/}" $CPU_TEST "no" "POD"
                fi
            fi
        fi
    done
}

function exec_udp_test() {
    PPS=$1
    BYTE=$2
    ID_EXP=$3
    N=$4
    RUN_TEST_SAME=$5
    RUN_TEST_SAMENODE=$6
    RUN_TEST_DIFF=$7
    RUN_TEST_CPU=$8
    V=$9
    BASE_FOLDER=${KITES_HOME}/pod-shared
    CPU_TEST="UDP"
    INTER_EXPERIMENT_SLEEP=3
    FOLDER_SINGLE_POD=single-pod

    for ((minion_n = 1; minion_n <= $N; minion_n++)); do
        folder_pod=pod$minion_n
        declare -x FOLDER_POD_$minion_n=$folder_pod
    done

    log_debug "Copy Pod-Shared on Root of the PODS"
    for ((minion_n = 1; minion_n <= $N; minion_n++)); do
        declare name1_pod="POD_NAME_$minion_n"
        kctl_exec ${!name1_pod} "cp -r ${KITES_HOME}/pod-shared /"
    done
    if $RUN_TEST_SAMENODE; then
        kctl_exec $SINGLE_POD_NAME "cp -r ${KITES_HOME}/pod-shared /"
    fi
    if $RUN_TEST_SAME || $RUN_TEST_DIFF; then
        for ((i = 1; i <= $N; i++)); do
            declare folder1p_name="FOLDER_POD_$i"
            cd $BASE_FOLDER/${!folder1p_name} || {
                log_error "Failure"
                exit 1
            }
            log_debug "$ID_EXP"
            log_debug "..................POD $i TEST.................."
            log_debug "----------------------------------------------"
            for ((j = 1; j <= $N; j++)); do
                declare name1_pod="POD_NAME_$i"
                declare name2_pod="POD_NAME_$j"
                if [ "$V" == "4" ]; then
                    declare ip1_pod="POD_IP_$i"
                    declare ip2_pod="POD_IP_$j"
                elif [ "$V" == "6" ]; then
                    declare ip1_pod="POD_IP6_$i"
                    declare ip2_pod="POD_IP6_$j"
                fi
                declare host1_pod="POD_HOSTNAME_$i"
                declare host2_pod="POD_HOSTNAME_$j"
                declare folder2p_name="FOLDER_POD_$j"
                if [ "$i" -eq "$j" ] && $RUN_TEST_SAME; then
                    if $RUN_TEST_CPU; then
                        start_cpu_monitor_nodes $N "samepod" 0 "${!host1_pod//[$' ']/}" $CPU_TEST $BYTE $PPS
                    fi
                    kctl_exec ${!name1_pod} "${KITES_HOME}/scripts/linux/netsniff-test.sh samePod$i-${BYTE}byte.pcap ${!ip1_pod} ${!ip1_pod} ${!host1_pod} ${!host1_pod} ${!name1_pod} ${!name1_pod} ${!folder1p_name} $BYTE $PPS $ID_EXP" &
                    sleep 2 &&
                        kctl_exec ${!name1_pod} "${KITES_HOME}/scripts/linux/trafgen-test.sh samePod$i-${BYTE}byte.cfg ${!ip1_pod} ${!ip1_pod} ${!host1_pod} ${!host1_pod} ${!name1_pod} ${!name1_pod} ${!folder1p_name} $BYTE $PPS $ID_EXP"
                    if $RUN_TEST_CPU; then
                        stop_cpu_monitor_nodes $N "samepod" 0 "${!host1_pod//[$' ']/}" $CPU_TEST $BYTE $PPS
                    fi
                elif [ "${!host1_pod}" != "${!host2_pod}" ] && $RUN_TEST_DIFF; then
                    if $RUN_TEST_CPU; then
                        start_cpu_monitor_nodes $N "diffnode" 2 "${!host2_pod//[$' ']/}TO${!host1_pod//[$' ']/}" $CPU_TEST $BYTE $PPS
                    fi
                    kctl_exec ${!name1_pod} "${KITES_HOME}/scripts/linux/netsniff-test.sh pod${j}ToPod${i}-${BYTE}byte.pcap ${!ip2_pod} ${!ip1_pod} ${!host2_pod} ${!host1_pod} ${!name2_pod} ${!name1_pod} ${!folder1p_name} $BYTE $PPS $ID_EXP" &
                    sleep 2 &&
                        kctl_exec ${!name2_pod} "${KITES_HOME}/scripts/linux/trafgen-test.sh pod${j}ToPod${i}-${BYTE}byte.cfg ${!ip2_pod} ${!ip1_pod} ${!host2_pod} ${!host1_pod} ${!name2_pod} ${!name1_pod} ${!folder2p_name} $BYTE $PPS $ID_EXP"
                    if $RUN_TEST_CPU; then
                        stop_cpu_monitor_nodes $N "diffnode" 2 "${!host2_pod//[$' ']/}TO${!host1_pod//[$' ']/}" $CPU_TEST $BYTE $PPS
                    fi
                fi
                sleep $INTER_EXPERIMENT_SLEEP
            done
        done
    fi

    if $RUN_TEST_SAMENODE; then
        log_debug "................SINGLE POD TEST................"
        log_debug "----------------------------------------------"
        if [ "$V" == "4" ]; then
        declare s_pod_ip="SINGLE_POD_IP"
    elif [ "$V" == "6" ]; then
        declare s_pod_ip="SINGLE_POD_IP6"
    fi
        if $RUN_TEST_SAME; then
            if $RUN_TEST_CPU; then
                start_cpu_monitor_nodes $N "samepod" 0 "$SINGLE_POD_HOSTNAME" $CPU_TEST $BYTE $PPS
            fi
            kctl_exec $SINGLE_POD_NAME "${KITES_HOME}/scripts/linux/netsniff-test.sh singlePodToSinglePod-${BYTE}byte.pcap ${!s_pod_ip} ${!s_pod_ip} $SINGLE_POD_HOSTNAME $SINGLE_POD_HOSTNAME $SINGLE_POD_NAME $SINGLE_POD_NAME $FOLDER_SINGLE_POD $BYTE $PPS $ID_EXP" &
            sleep 2 &&
                kctl_exec $SINGLE_POD_NAME "${KITES_HOME}/scripts/linux/trafgen-test.sh singlePodToSinglePod-${BYTE}byte.cfg ${!s_pod_ip} ${!s_pod_ip} $SINGLE_POD_HOSTNAME $SINGLE_POD_HOSTNAME $SINGLE_POD_NAME $SINGLE_POD_NAME $FOLDER_SINGLE_POD $BYTE $PPS $ID_EXP"
            if $RUN_TEST_CPU; then
                stop_cpu_monitor_nodes $N "samepod" 0 "$SINGLE_POD_HOSTNAME" $CPU_TEST $BYTE $PPS
            fi
            sleep $INTER_EXPERIMENT_SLEEP
        fi
        for ((minions_n = 1; minions_n <= $N; minions_n++)); do
            declare name1_pod="POD_NAME_$minions_n"
            if [ "$V" == "4" ]; then
                declare ip1_pod="POD_IP_$minions_n"
            elif [ "$V" == "6" ]; then
                declare ip1_pod="POD_IP6_$minions_n"
            fi
            declare host1_pod="POD_HOSTNAME_$minions_n"
            declare folder1p_name="FOLDER_POD_$minions_n"
            if ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" = "${!host1_pod//[$' ']/}" ] && $RUN_TEST_SAMENODE) || ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" != "${!host1_pod//[$' ']/}" ] && $RUN_TEST_DIFF); then
                if $RUN_TEST_CPU; then
                    if [ "${SINGLE_POD_HOSTNAME//[$' ']/}" = "${!host1_pod//[$' ']/}" ]; then
                        start_cpu_monitor_nodes $N "samenode" 1 "${!host1_pod//[$' ']/}" $CPU_TEST $BYTE $PPS
                    else
                        start_cpu_monitor_nodes $N "diffnode" 2 "${SINGLE_POD_HOSTNAME//[$' ']/}TO${!host1_pod//[$' ']/}" $CPU_TEST $BYTE $PPS
                    fi
                fi
                kctl_exec ${!name1_pod} "${KITES_HOME}/scripts/linux/netsniff-test.sh singlePodToPod$minions_n-${BYTE}byte.pcap ${!s_pod_ip} ${!ip1_pod} $SINGLE_POD_HOSTNAME ${!host1_pod} $SINGLE_POD_NAME ${!name1_pod} ${!folder1p_name} $BYTE $PPS $ID_EXP" &
                sleep 2 &&
                    kctl_exec $SINGLE_POD_NAME "${KITES_HOME}/scripts/linux/trafgen-test.sh singlePodToPod$minions_n-${BYTE}byte.cfg ${!s_pod_ip} ${!ip1_pod} $SINGLE_POD_HOSTNAME ${!host1_pod} $SINGLE_POD_NAME ${!name1_pod} $FOLDER_SINGLE_POD $BYTE $PPS $ID_EXP"
                if $RUN_TEST_CPU; then
                    if [ "${SINGLE_POD_HOSTNAME//[$' ']/}" = "${!host1_pod//[$' ']/}" ]; then
                        stop_cpu_monitor_nodes $N "samenode" 1 "${!host1_pod//[$' ']/}" $CPU_TEST $BYTE $PPS
                    else
                        stop_cpu_monitor_nodes $N "diffnode" 2 "${SINGLE_POD_HOSTNAME//[$' ']/}TO${!host1_pod//[$' ']/}" $CPU_TEST $BYTE $PPS
                    fi
                fi
            fi
            sleep $INTER_EXPERIMENT_SLEEP
        done
    fi

    log_debug "Copy Root on Pod-Shared"
    for ((minion_n = 1; minion_n <= $N; minion_n++)); do
        declare name1_pod="POD_NAME_$minion_n"
        kctl_exec ${!name1_pod} "cp -r /pod-shared ${KITES_HOME}/ && rm -r /pod-shared"
    done
    if $RUN_TEST_SAMENODE; then
        kctl_exec $SINGLE_POD_NAME "cp -r /pod-shared ${KITES_HOME}/ && rm -r /pod-shared"
    fi

}

function exec_net_test() {
    log_inf "Start execution net test."
    N=$1
    TCP_TEST=$2
    UDP_TEST=$3
    RUN_TEST_SAME=$4
    RUN_TEST_SAMENODE=$5
    RUN_TEST_DIFF=$6
    RUN_TEST_CPU=$7
    ID_EXP=$8
    shift 8
    bytes=("$@")
    
    if [ "$RUN_IPV4_ONLY" == "true" ]; then
        declare version="4"
    elif [ "$RUN_IPV6_ONLY" == "true" ]; then
        declare version="6"
    fi

    log_debug "${bytes[*]}"
    if $UDP_TEST; then
        log_debug "UDP TEST"
        log_debug "$ID_EXP"
        for byte in "${bytes[@]}"; do
            log_debug "$byte $PPS_MIN $PPS_MAX $PPS_INC $pps"
            for ((pps = $PPS_MIN; pps <= $PPS_MAX; pps += $PPS_INC)); do
                log_debug "____________________________________________________"
                log_debug "$byte bytes. TRAFFIC LOAD: ${pps}pps "
                log_debug "____________________________________________________"
                exec_udp_test "$pps" "$byte" "$ID_EXP" "$N" "$RUN_TEST_SAME" "$RUN_TEST_SAMENODE" "$RUN_TEST_DIFF" "$RUN_TEST_CPU" "$version"
                ${KITES_HOME}/scripts/linux/merge-udp-test.sh $pps $byte $N $RUN_TEST_SAMENODE
            done
        done
    fi

    ###TCP TEST FOR PODS AND NODES WITH IPERF3
    if $TCP_TEST; then
        log_debug "TCP TEST"
        cd "${KITES_HOME}/pod-shared" || {
            log_error "Failure"
            exit 1
        }
        log_debug "TCP TEST between pods"
        echo -e "TCP TEST\n" >TCP_IPERF_OUTPUT.txt
        exec_tcp_test_between_pods "$ID_EXP" "$N" "$RUN_TEST_SAME" "$RUN_TEST_SAMENODE" "$RUN_TEST_DIFF" "$RUN_TEST_CPU"

        log_debug "TCP TEST between nodes"
        echo -e "TCP TEST NODES\n" >TCP_IPERF_NODE_OUTPUT.txt
        for ((minion_n = 1; minion_n <= "$N"; minion_n++)); do
            declare node_ip="NODE_IP_$minion_n"
            sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-"${minion_n}".k8s-play.local "${KITES_HOME}/scripts/linux/tcp-test-node.sh $ID_EXP $N ${!node_ip} $version "$RUN_TEST_SAME" "$RUN_TEST_SAMENODE" "$RUN_TEST_DIFF" "$RUN_TEST_CPU""
        done
    fi
}

function parse_test() {
    log_inf "Start parsing test results."
    CNI=$1
    N=$2
    TCP_TEST=$3
    UDP_TEST=$4
    RUN_CPU_TEST=$5
    ID_EXP=$6
    shift 6
    bytes=("$@")
    log_debug "${bytes[@]}"

    if [ ! -d "${KITES_HOME}/pod-shared/tests/$CNI" ]; then
        log_debug "Directory ${KITES_HOME}/pod-shared/tests/$CNI doesn't exists."
        log_debug "Creating: Directory ${KITES_HOME}/pod-shared/tests/$CNI"
        mkdir -p "${KITES_HOME}/pod-shared/tests/$CNI"
    fi

    if [ $ID_EXP == "exp-0" ] || [ $ID_EXP == "exp-1" ]; then
        log_debug "Removing contents inside ${KITES_HOME}/tests/"
        rm -rf "${KITES_HOME}/tests/${CNI}"
    fi

    if [ ! -d "${KITES_HOME}/tests/${CNI}/${ID_EXP}" ]; then
        log_debug "Directory ${KITES_HOME}/tests/${CNI}/${ID_EXP} doesn't exists."
        log_debug "Creating: Directory ${KITES_HOME}/tests/${CNI}/${ID_EXP}/"
        mkdir -p ${KITES_HOME}/tests/${CNI}/${ID_EXP}
    fi

    cd "${KITES_HOME}/pod-shared/tests/$CNI" || {
        log_error "Failure"
        exit 1
    }

    if $UDP_TEST; then
        log_debug "Parsing UDP TEST into netsniff-tests"
        echo "CNI, TEST_TYPE, ID_EXP, BYTE, PPS, VM_SRC, VM_DEST, POD_SRC, POD_DEST, IP_SRC, IP_DEST, OUTGOING, INCOMING, PASSED, TX_TIME, RX_TIME, TIMESTAMP, CONFIG, CONFIG_CODE" >netsniff-tests.csv
        echo "OUTGOING, TX_TIME, VM_SRC, VM_DEST, POD_SRC, POD_DEST, PPS" >trafgen-tests.csv

        # CNI | Tipo di test | ID_EXP | PPS | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time | TIMESTAMP
        for byte in "${bytes[@]}"; do
            for ((pps = ${PPS_MIN}; pps <= ${PPS_MAX}; pps += ${PPS_INC})); do
                ${KITES_HOME}/scripts/linux/parse-netsniff-test.sh "$CNI" ${KITES_HOME}/pod-shared/NETSNIFF-${byte}byte-${pps}pps.txt ${KITES_HOME}/pod-shared/TRAFGEN-${byte}byte-${pps}pps.txt "$ID_EXP"
            done
        done

        log_debug "Computing results of UDP test"
        for byte in "${bytes[@]}"; do
            compute_udp_result netsniff-tests.csv "$CNI" $byte
            compute_udp_throughput udp_results_${CNI}_${byte}bytes.csv $CNI $byte
        done
        if $RUN_CPU_TEST; then
            log_debug "Computing CPU analysis of UDP test"
            compute_cpu_analysis_udp "UDP" $CNI $N $ID_EXP "${bytes[@]}"
        fi
    fi

    if $TCP_TEST; then
        log_debug "Parsing TCP TEST into iperf-tests"
        echo "CNI, TEST_TYPE, ID_EXP, VM_SRC, VM_DEST, POD_SRC, POD_DEST, IP_SRC, IP_DEST, OUTGOING, OUT_UNIT, INCOMING, INC_UNIT, THROUGHPUT, THR_UNIT, TX_TIME, RX_TIME, TIMESTAMP, CONFIG, CONFIG_CODE" >iperf-tests.csv
        #TCP TEST FOR PODS AND NODES WITH IPERF3
        ${KITES_HOME}/scripts/linux/parse-iperf-test.sh "$CNI" "${KITES_HOME}/pod-shared/TCP_IPERF_OUTPUT.txt" "$N"
        ${KITES_HOME}/scripts/linux/parse-iperf-test-node.sh "$CNI" "${KITES_HOME}/pod-shared/TCP_IPERF_NODE_OUTPUT.txt" "$N"
        if $RUN_CPU_TEST; then
            compute_cpu_analysis_tcp "TCP" $CNI $N
        fi
    fi

    log_debug "Moving results in ${KITES_HOME}/tests/"
    mv "${KITES_HOME}/pod-shared/tests/${CNI}" "${KITES_HOME}/tests/${CNI}/${ID_EXP}"

}

function compute_udp_throughput() {
    log_debug "Compute UDP Throughput, CNI $2 - byte $3."
    INPUT=$1
    CNI=$2
    byte=$3
    [ ! -f $INPUT ] && {
        log_debug "$INPUT file not found"
        return
    }

    echo "BYTE, PPS, CONFIG_CODE, CONFIG, RX/TX, TXED/TOTX, PacketRate" >udp_throughput_${CNI}_${byte}bytes.csv

    configs_names=("SamePod" "PodsOnSameNode" "PodsOnDiffNode")
    configs=("0" "1" "2")
    for config in "${configs[@]}"; do
        echo "for ${configs_names[$config]} ($config)"
        awk -F, '$3=='$config'' $INPUT >temp${configs_names[$config]}.csv

        #this takes the packet rate with the MAXIMUM rx/tx
        #awk -F, 'NR==1{s=m=$4}{a[$4]=$0;m=($4>m)?$4:m;s=($4<s)?$4:s}END{print a[m]}' temp${configs_names[$config]}.csv >> udp_throughput_max.csv

        #this takes the maximum packet rate which guarantees a rx/tx>0.95
        awk -F, '$5 > 0.95' temp${configs_names[$config]}.csv >temp.csv
        sort -k4 temp.csv >sortedtemp.csv
        awk -F, 'NR==1{s=m=$7}{a[$7]=$0;m=($7>m)?$7:m;s=($7<s)?$7:s}END{print a[m]}' sortedtemp.csv >>udp_throughput_${CNI}_${byte}bytes.csv
        rm temp${configs_names[$config]}.csv
        rm sortedtemp.csv
        rm temp.csv
    done
}

function compute_udp_result() {
    calc() { awk "BEGIN{ printf \"%.2f\n\", $* }"; }
    INPUT=$1
    CNI=$2
    byte=$3

    [ ! -f "$INPUT" ] && {
        echo "$INPUT file not found"
        exit 99
    }
    echo "BYTE, PPS, C, CONFIG, RX/TX, TXED/TOTX, PacketRate" >"udp_results_${CNI}_${byte}bytes.csv"

    awk -F"," '$4=='$byte'' $INPUT >bytetemp.csv
    for ((pps = $PPS_MIN; pps <= $PPS_MAX; pps += $PPS_INC)); do
        echo "byte, pps, c, config, rx/tx, txed/totx, PacketRate" >>"udp_results_${CNI}_${byte}bytes.csv"
        awk -F"," '$5=='$pps'' bytetemp.csv >temp.csv
        # configs_names=("SamePod" "PodsOnSameNode" "PodsOnDiffNode")
        # configs=("0" "1" "2")
        for config in "${RUN_CONFIG[@]}"; do
            awk -F, '$19=='${RUN_CONFIG_CODE[$config]}'' temp.csv >temp${config}.csv
            incoming_avg=$(awk -F',' '{sum+=$13; ++n} END { print sum/n }' <temp${config}.csv)
            outgoing_avg=$(awk -F',' '{sum+=$12; ++n} END { print sum/n }' <temp${config}.csv)
            # echo "avg_inc $incoming_avg"
            # echo "avg_out $outgoing_avg"
            rxtx_ratio=$(calc $incoming_avg/$outgoing_avg)
            totxpkt=$((pps * 10))
            txedtx_ratio=$(calc $outgoing_avg/$totxpkt)
            real_pktrate=$(calc $pps*$txedtx_ratio)
            # echo "real_pktrate $real_pktrate"
            echo "$byte, $pps, ${RUN_CONFIG_CODE[$config]}, ${config}, $rxtx_ratio, $txedtx_ratio, $real_pktrate" >>udp_results_${CNI}_${byte}bytes.csv
            rm temp${config}.csv
        done
        rm temp.csv
    done
    rm bytetemp.csv

}

function compute_cpu_analysis_udp() {
    calc() { awk "BEGIN{ printf \"%.2f\n\", $* }"; }
    CPU_TEST=$1
    CNI=$2
    N=$3
    ID_EXP=$4
    shift 4
    bytes=("$@")

    cd "$KITES_HOME/cpu" || {
        log_error "Failure"
        exit 1
    }

    cpus_master=$(cat /proc/cpuinfo | grep processor | wc -l)
    for ((cpu_n=0; cpu_n<$cpus_master; cpu_n++)); do
        columns[$cpu_n]=$((5 + cpu_n))
    done
    for ((minion_n = 1; minion_n <= $N; minion_n++)); do
        minions[${#minions[@]}]="cpu_avg_minion-${minion_n}"
        INPUT=cpu-k8s-minion-${minion_n}-$CPU_TEST-${bytes[0]}bytes
        columns_n=$(head -1 ${INPUT}.csv | sed 's/[^,]//g' | wc -c)
        cpus_minion=$((columns_n - 6))
        if [ $cpus_minion -gt 1 ]; then
            for ((cpu_n=0; cpu_n<$cpus_minion; cpu_n++)); do
                minions[${#minions[@]}]="cpu${cpu_n}-from-minion-${minion_n}"
            done
        fi
    done
    printf -v minions_comma '%s,' "${minions[@]}"
    cpu_from_master[${#cpu_from_master[@]}]="cpu_avg_master"
    if [ $cpus_master -gt 1 ]; then
        for ((cpu_n=0; cpu_n<$cpus_master; cpu_n++)); do
            cpu_from_master[${#cpu_from_master[@]}]="cpu${cpu_n}-from-master"
        done
    fi
    printf -v cpu_master_comma '%s,' "${cpu_from_master[@]}"
   

    for byte in "${bytes[@]}"; do
        echo "PPS, C, CONFIG, TEST_TYPE, ${cpu_master_comma%,}, ${minions_comma%,}, rx/tx, txed/totx" >"cpu-usage-${CNI}-${CPU_TEST}-${byte}bytes.csv"
    done

    
    for byte in "${bytes[@]}"; do
        files[0]=cpu-k8s-master-1-$CPU_TEST-${byte}bytes
        for ((minion_n = 1; minion_n <= $N; minion_n++)); do
            INPUT=cpu-k8s-minion-${minion_n}-$CPU_TEST-${byte}bytes
            files[$minion_n]=$INPUT
        done
        
        for i in "${!files[@]}"; do
            if [ $i -eq 0 ]; then
                cpus=$cpus_master
            else
                cpus=$cpus_minion
            fi
            
            for ((pps = $PPS_MIN; pps <= $PPS_MAX; pps += $PPS_INC)); do
                unset cpu_avg_n
                # echo ${cpu_avg_a[*]}
                cpu_avg_n[${#cpu_avg_n[@]}]="cpu_avg"
                if [ $cpus -gt 1 ]; then
                    for ((cpu_n=0; cpu_n<$cpus; cpu_n++)); do
                        cpu_avg_n[${#cpu_avg_n[@]}]="cpu${cpu_n}"
                    done
                fi
                printf -v cpu_avg_comma '%s,' "${cpu_avg_n[@]}"
                echo "pps, c, config, test_type, ${cpu_avg_comma%,}, rx/tx, txed/totx" >>"cpu_usage_${files[i]}.csv"
                awk -F"," '$1=='$pps'' ${files[i]}.csv >temp_pps.csv
                for config in "${RUN_CONFIG[@]}"; do
                    unset cpu_avg
                    awk -F, '$3=='${RUN_CONFIG_CODE[$config]}'' temp_pps.csv >temp${config}.csv
                    udp_results=$(awk -F, '$2=='$pps' && $3=='${RUN_CONFIG_CODE[$config]}' { print $5","$6 }' ${KITES_HOME}/pod-shared/tests/${CNI}/udp_results_${CNI}_${byte}bytes.csv)
                    # echo "udp_res = $udp_results"
                    if ([[ ${config} == "samepod" ]] || [[ ${config} == "samenode" ]]); then
                        for ((minion_n = 1; minion_n <= $N; minion_n++)); do
                            unset cpu_avg
                            awk -F"," '$4 ~ /'k8s-minion-$minion_n'/' temp${config}.csv >temp_minion.csv
                            if [ -s temp_minion.csv ]; then
                                cpu_avg[${#cpu_avg[@]}]=$(awk -F',' '{sum+=$6; ++n} END { print sum/n }' <temp_minion.csv)
                                if [ $cpus -gt 1 ]; then
                                    for ((cpu_n=0; cpu_n<$cpus; cpu_n++)); do
                                        cpu_avg[${#cpu_avg[@]}]=$(awk -F',' '{sum+=$'$((7 + $cpu_n))'; ++n} END { print sum/n }' <temp_minion.csv)
                                    done
                                fi
                                printf -v cpuavg_comma '%s,' "${cpu_avg[@]}"
                                echo "$pps, ${RUN_CONFIG_CODE[$config]}, ${config}, k8s-minion-$minion_n, ${cpuavg_comma%,}, $udp_results" >>cpu_usage_${files[i]}.csv
                            fi
                        done
                    elif [[ ${config} == "diffnode" ]]; then
                        for ((m_i = 1; m_i <= $N; m_i++)); do
                            for ((m_j = 1; m_j <= $N; m_j++)); do
                                if [ $m_j -ne $m_i ]; then

                                    for ((cpu_n=0; cpu_n<=$cpus; cpu_n++)); do
                                        if ! ( [ $cpus -eq 1 ] && [ $cpu_n -eq 1 ] ); then
                                            awk -F"," '$4 ~ /'k8s-minion-${m_i}TOk8s-minion-${m_j}'/' temp${config}.csv >temp_minion.csv
                                            count=$(awk -F',' 'BEGIN {n=0} $'$((6 + $cpu_n))'==100 {n++} END {print n}' <temp_minion.csv)
                                            total=$(awk -F',' '{n++} END {print n}' <temp_minion.csv)
                                            percentage=$(calc 0.75*$total)
                                            if (($(echo "$count $percentage" | awk '{print ($1 > $2)}'))); then
                                                cpu_avg[$cpu_n]=100
                                            else
                                                cpu_avg[$cpu_n]=$(awk -F',' '{sum+=$'$((6 + $cpu_n))'; ++n} END { print sum/n }' <temp_minion.csv)
                                            fi
                                        fi
                                    done
                                    printf -v cpuavg_comma '%s,' "${cpu_avg[@]}"
                                    echo "$pps, ${RUN_CONFIG_CODE[$config]}, ${config}, k8s-minion-${m_i}TOk8s-minion-${m_j}, ${cpuavg_comma%,}, $udp_results" >>cpu_usage_${files[i]}.csv
                                fi
                            done
                        done
                    fi
                    
                    rm temp_minion.csv
                    rm temp${config}.csv
                done
                rm temp_pps.csv
            done
            unset columns
            columns[${#columns[@]}]=5
            if [ $cpus -gt 1 ]; then
                for ((cpu_n=0; cpu_n<$cpus; cpu_n++)); do
                    columns[${#columns[@]}]=$((6 + cpu_n))
                done
            fi
            rx_n=$((columns[-1] + 1))
            tx_n=$((columns[-1] + 2))
            echo "results #: $rx_n,$tx_n"
            printf -v columns_comma '%s,' "${columns[@]}"
            echo $i
            echo ${columns_comma%,}
            cut -d, -f "${columns_comma%,}" cpu_usage_${files[i]}.csv >temp_cpus$i.csv
            cut -d, -f $rx_n,$tx_n cpu_usage_${files[i]}.csv >res_udp.csv
            cut -d, -f 1,2,3,4 cpu_usage_${files[i]}.csv >info.csv
            cpu_file[i]=temp_cpus$i.csv
        done
        paste -d, info.csv ${cpu_file[*]} res_udp.csv >>cpu-usage-${CNI}-${CPU_TEST}-${byte}bytes.csv
        # rm ${cpu_file[*]}
        mv "cpu-usage-${CNI}-${CPU_TEST}-${byte}bytes.csv" "${KITES_HOME}/tests/${CNI}/${ID_EXP}/"
    done
}

function compute_cpu_analysis_tcp() {
    calc() { awk "BEGIN{ printf \"%.2f\n\", $* }"; }
    CPU_TEST=$1
    CNI=$2
    N=$3

    cd "$KITES_HOME/cpu" || {
        log_error "Failure"
        exit 1
    }

    files[0]=cpu-k8s-master-1-$CPU_TEST-nobytes
    columns[0]=5
    for ((minion_n = 1; minion_n <= $N; minion_n++)); do
        INPUT=cpu-from-minion-${minion_n}
        INPUT_CPU=cpu-k8s-minion-${minion_n}-$CPU_TEST-nobytes
        files[$minion_n]=$INPUT_CPU
        minions[$minion_n]=$INPUT
        n=$((minion_n - 1))
        col=$((columns[n] + 6))
        columns[minion_n]=$col
    done
    n1=$((N + 1))
    columns[n1]=$((columns[N] + 1))
    printf -v columns_comma '%s,' "${columns[@]}"
    printf -v minions_comma '%s,' "${minions[@]}"
    echo ${files[*]}

    echo "TCP-CONFIG, C, CONFIG, TEST_TYPE, cpu-from-master, ${minions_comma%,}, throughput" >"cpu-usage-${CNI}-${CPU_TEST}.csv"

    for i in "${!files[@]}"; do
        echo "tcp-config, c, config, test_type, cpu_avg, throughput (Gbps)" >>"cpu_usage_${files[i]}.csv"
        tcp_configs=("POD" "NO_POD")
        for tcp_config in "${!tcp_configs[@]}"; do
            if [ ${tcp_configs[$tcp_config]} == "POD" ]; then
                awk -F"," '$6 !~ /'NO_POD'/' ${KITES_HOME}/pod-shared/tests/${CNI}/iperf-tests.csv >temp_tcp_config.csv
                awk -F"," '$1 !~ /'NO_POD'/' ${files[i]}.csv >temp_cpu_config.csv
            else
                awk -F"," '$6 ~ /'NO_POD'/' ${KITES_HOME}/pod-shared/tests/${CNI}/iperf-tests.csv >temp_tcp_config.csv
                awk -F"," '$1 ~ /'NO_POD'/' ${files[i]}.csv >temp_cpu_config.csv
            fi
            for config in "${RUN_CONFIG[@]}"; do
                awk -F, '$2 ~ /'${config}'/' temp_cpu_config.csv >temp_cpu_${config}.csv
                if ([[ ${config} == "samepod" ]] && [[ ${tcp_configs[$tcp_config]} == "POD" ]]) || ([[ ${config} == "samenode" ]]); then
                    for ((minion_n = 1; minion_n <= $N; minion_n++)); do
                        awk -F"," '$4 ~ /'k8s-minion-$minion_n'/' temp_cpu_${config}.csv >temp_minion.csv
                        if [ -s temp_minion.csv ]; then
                            cpu_avg=$(awk -F',' '{sum+=$6; ++n} END { print sum/n }' <temp_minion.csv)
                            tcp_thr=$(awk -F',' '$20=='${RUN_CONFIG_CODE[$config]}' && $4 ~ /'k8s-minion-$minion_n'/ {sum+=$14; ++n} END { print sum/n }' temp_tcp_config.csv)
                            echo "${tcp_configs[$tcp_config]}, ${RUN_CONFIG_CODE[$config]}, ${config}, k8s-minion-$minion_n, $cpu_avg, $tcp_thr" >>cpu_usage_${files[i]}.csv
                        fi
                    done
                elif [[ ${config} == "diffnode" ]]; then
                    for ((m_i = 1; m_i <= $N; m_i++)); do
                        for ((m_j = 1; m_j <= $N; m_j++)); do
                            if [ $m_j -ne $m_i ]; then
                                awk -F"," '$4 ~ /'k8s-minion-${m_i}TOk8s-minion-${m_j}'/' temp_cpu_${config}.csv >temp_minion.csv
                                count=$(awk -F',' 'BEGIN {n=0} $6==100 {n++} END {print n}' <temp_minion.csv)
                                total=$(awk -F',' 'BEGIN {n=0} {n++} END {print n}' <temp_minion.csv)
                                percentage=$(calc 0.75*$total)
                                if [[ $count > $percentage ]]; then
                                    cpu_avg=100
                                else
                                    cpu_avg=$(awk -F',' '{sum+=$6; ++n} END { print sum/n }' <temp_minion.csv)
                                fi
                                tcp_thr=$(awk -F',' '$20=='${RUN_CONFIG_CODE[$config]}' && $4 ~ /'k8s-minion-${m_i}'/ && $5 ~ /'k8s-minion-${m_j}'/ {sum+=$14; ++n} END { print sum/n }' temp_tcp_config.csv)
                                echo "${tcp_configs[$tcp_config]}, ${RUN_CONFIG_CODE[$config]}, ${config}, k8s-minion-${m_i}TOk8s-minion-${m_j}, $cpu_avg, $tcp_thr" >>cpu_usage_${files[i]}.csv
                            fi
                        done
                    done
                fi
                cpu_file[i]=cpu_usage_${files[i]}.csv
                if [ -s temp_minion.csv ]; then rm temp_minion.csv; fi
                rm temp_cpu_${config}.csv
            done
            rm temp_tcp_config.csv
            rm temp_cpu_config.csv
        done
    done
    paste -d, ${cpu_file[*]} | cut -d, -f 1,2,3,4,"${columns_comma%,}" >>cpu-usage-${CNI}-${CPU_TEST}.csv
    rm ${cpu_file[*]}
    mv cpu-usage-${CNI}-${CPU_TEST}.csv ${KITES_HOME}/tests/${CNI}/${ID_EXP}
}

function print_all_setup_parameters() {
    log_debug "Setup parameters:"
    log_debug " KITES_HOME=${KITES_HOME}"
    log_debug " KITES_NAMSPACE_NAME=${KITES_NAMSPACE_NAME}"
    log_debug " N=${N}"
    log_debug " RUN_TEST_TCP=${RUN_TEST_TCP}"
    log_debug " RUN_TEST_UDP=${RUN_TEST_UDP}"
    log_debug " RUN_TEST_SAME=${RUN_TEST_SAME}"
    log_debug " RUN_TEST_SAMENODE=${RUN_TEST_SAMENODE}"
    log_debug " RUN_TEST_DIFF=${RUN_TEST_DIFF}"
    log_debug " RUN_CONFIG=${RUN_CONFIG[*]}"
    log_debug " RUN_CONFIG_CODE=${RUN_CONFIG_CODE[*]}"
    log_debug " RUN_TEST_CPU=${RUN_TEST_CPU}"
    log_debug " CLEAN_ALL=${CLEAN_ALL}"
    log_debug " RUN_IPV4_ONLY=${RUN_IPV4_ONLY}"
    log_debug " RUN_IPV6_ONLY=${RUN_IPV6_ONLY}"
    log_debug " PKT_BYTES=${PKT_BYTES[*]}"
    log_debug " PPS_MIN=${PPS_MIN}"
    log_debug " PPS_MAX=${PPS_MAX}"
    log_debug " PPS_INC=${PPS_INC}"
    log_debug " VERBOSITY_LEVEL=${VERBOSITY_LEVEL}"
    log_debug " repeatable=${repeatable}"
    log_debug " number of repetitions=${EXP_N}"
}

#   Parse arguments
##

while [ $# -gt 0 ]; do
    arg=$1
    case $arg in
    --cni)
        CNI=$2
        ;;
    --nodes)
        N=$2
        ;;
    --namespace | -n)
        KITES_NAMSPACE_NAME=$2
        ;;
    --clean-all)
        CLEAN_ALL="true"
        ;;
    -4)
        RUN_IPV4_ONLY="true"
        RUN_IPV6_ONLY="false"
        ;;
    -6)
        RUN_IPV4_ONLY="false"
        RUN_IPV6_ONLY="true"
        ;;
    --test-type | -t)

        RUN_TEST_TCP="false"
        RUN_TEST_UDP="false"
        for i in $(awk '{gsub(/,/," ");print}' <<<"$2"); do
            case $i in
            all)
                RUN_TEST_TCP="true"
                RUN_TEST_UDP="true"
                ;;
            tcp)
                RUN_TEST_TCP="true"
                ;;
            udp)
                RUN_TEST_UDP="true"
                ;;
            *) log_error "Invalid argument: $1\n" && display_usage && exit ;;
            esac
        done
        ;;
    --conf)
        #shift
        unset RUN_CONFIG
        unset RUN_CONFIG_CODE
        declare -A RUN_CONFIG_CODE
        RUN_TEST_SAME="false"
        RUN_TEST_SAMENODE="false"
        RUN_TEST_DIFF="false"
        k=0
        for i in $(awk '{gsub(/,/," ");print}' <<<"$2"); do
            case $i in
            all)
                RUN_TEST_SAME="true"
                RUN_TEST_SAMENODE="true"
                RUN_TEST_DIFF="true"
                ;;
            samepod)
                RUN_TEST_SAME="true"
                RUN_CONFIG[$k]=$i
                RUN_CONFIG_CODE[$i]=0
                k=$((k + 1))
                ;;
            samenode)
                RUN_TEST_SAMENODE="true"
                RUN_CONFIG[$k]=$i
                RUN_CONFIG_CODE[$i]=1
                k=$((k + 1))
                ;;
            diffnode)
                RUN_TEST_DIFF="true"
                RUN_CONFIG[$k]=$i
                RUN_CONFIG_CODE[$i]=2
                k=$((k + 1))
                ;;
            *) error "Invalid argument: $1\n" && display_usage && exit ;;
            esac
        done
        ;;
    --nocpu | -nc)
        RUN_TEST_CPU="false"
        ;;
    --bytes | -b)
        shift
        k=0
        for i in $(awk '{gsub(/,/," ");print}' <<<"$1"); do
            PKT_BYTES[$k]=$i
            k=$((k + 1))
        done
        ;;

    --repeat | -r)
        # shift
        repeatable="true"
        EXP_N=$2
        ;;

    --monitor | -m)
        # shift
        monitoing="true"
        ;;

    --help | -h)
        display_usage && exit
        ;;
        # *)
        #     error "Invalid argument: $1\n" && display_usage && exit
        #     ;;
    esac
    shift
done

if $CLEAN_ALL; then
    clean_all
else
    clean_pod_shared_dir
    clean_cpu_monitoring_dir
fi

if [ "$CNI" = "" ]; then
    display_usage && exit
fi
print_all_setup_parameters

if $monitoing; then
    prometheus_monitoring
fi

start=$(date +%s)
log_inf "KITES start."

if $RUN_TEST_CPU; then
    # TO CHECK
    start_cpu_monitor_nodes $N "IDLE" "-" "IDLE" "no_node" "no_pkt" "no_pps"
    sleep 10
    stop_cpu_monitor_nodes $N "IDLE" "-" "IDLE" "no_node" "no_pkt" "no_pps"
fi

create_name_space
initialize_net_test "$CNI" "$N" $RUN_TEST_UDP $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF "${PKT_BYTES[@]}"
if $repeatable; then
    for ((exp_n = 1; exp_n <= $EXP_N; exp_n++)); do
        log_debug "Starting $exp_n experiment"
        ID_EXP=exp-$exp_n
        RUN_TEST_TCP="false"
        exec_net_test "$N" $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF $RUN_TEST_CPU "$ID_EXP" "${PKT_BYTES[@]}"
        parse_test "$CNI" "$N" $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_CPU "$ID_EXP" "${PKT_BYTES[@]}"
        cd "${KITES_HOME}/pod-shared" || {
            log_error "Failure"
            exit 1
        }
        shopt -s globstar
        rm -f -- **/*.txt
    done
else
    ID_EXP=exp-$EXP_N
    exec_net_test "$N" $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF $RUN_TEST_CPU "$ID_EXP" "${PKT_BYTES[@]}"
    parse_test "$CNI" "$N" $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_CPU "$ID_EXP" "${PKT_BYTES[@]}"
fi

if $RUN_TEST_UDP; then
    for byte in "${PKT_BYTES[@]}"; do
        log_debug "Creating plot for packets of $byte bytes"
        python3.7 ${KITES_HOME}/plot/compute-experiments-result.py $CNI $byte $N
    done
fi

if $RUN_TEST_TCP; then
    log_debug "Creating plot for TCP traffic"
    python3.7 ${KITES_HOME}/plot/compute-tcp-plot.py $CNI $N
fi

end=$(date +%s)
exec_time=$(expr $end - $start)
exec_min=$(expr $exec_time / 60)
exec_hour=$(expr $exec_min / 60)
log_inf "KITES stop. Execution time was $exec_min minutes, $exec_hour hours."
log_debug "Carla is a killer of VMs."
log_debug "Saving experiment infos in exp_info.txt"
cd "$KITES_HOME/tests/$CNI" || {
    log_error "Failure"
    exit 1
}
echo " "Setup parameters:"
     " KITES_HOME=${KITES_HOME}"
     " KITES_NAMSPACE_NAME=${KITES_NAMSPACE_NAME}"
     " N=${N}"
     " RUN_TEST_TCP=${RUN_TEST_TCP}"
     " RUN_TEST_UDP=${RUN_TEST_UDP}"
     " RUN_TEST_SAME=${RUN_TEST_SAME}"
     " RUN_TEST_SAMENODE=${RUN_TEST_SAMENODE}"
     " RUN_TEST_DIFF=${RUN_TEST_DIFF}"
     " RUN_CONFIG=${RUN_CONFIG[*]}"
     " RUN_CONFIG_CODE=${RUN_CONFIG_CODE[*]}"    
     " RUN_TEST_CPU=${RUN_TEST_CPU}"
     " CLEAN_ALL=${CLEAN_ALL}"
     " RUN_IPV4_ONLY=${RUN_IPV4_ONLY}"
     " RUN_IPV6_ONLY=${RUN_IPV6_ONLY}"
     " PKT_BYTES=${PKT_BYTES[*]}"
     " PPS_MIN=${PPS_MIN}"
     " PPS_MAX=${PPS_MAX}"
     " PPS_INC=${PPS_INC}"
     " VERBOSITY_LEVEL=${VERBOSITY_LEVEL}"" >>exp_info.txt
echo "KITES stop. Execution time was $exec_min minutes, $exec_hour hours." >>exp_info.txt
