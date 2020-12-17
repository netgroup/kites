#!/bin/bash
. utils/logging.sh
. utils/check-dependencies.sh

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
    echo "  --test-type | -t    : set the test-type between: all, tcp, udp. Default set =all"
    echo "  --conf              : set the configuration between: all, samepod, samenode, diffnode. Default set =all"
    echo "  --clean-all         : remove all experiment data and pods already created."
    echo "  --namespace | -n    : set the namespace name. Default set =kites"
    #echo "  --dual-stack        : use IPv4 and IPv6 if enabled."
    echo "  -4                  : use IPv4 only."
    echo "  -6                  : use IPv6 only."
    echo "  -h                  : display this help message"
}

[ "$1" = "" ] && display_usage && exit

##
#   Deafult parameters
##

declare -xg KITES_HOME="/vagrant/ext/kites"
declare -xg KITES_NAMSPACE_NAME="kites"

N=2
RUN_TEST_TCP="true"
RUN_TEST_UDP="true"
RUN_TEST_SAME="true"
RUN_TEST_SAMENODE="true"
RUN_TEST_DIFF="true"
RUN_TEST_CPU="true"
CLEAN_ALL="false"
IPv6DualStack="false"
RUN_IPV4_ONLY="true"
RUN_IPV6_ONLY="false"
VERBOSITY_LEVEL=5 # default debug level. see in utils/logging.sh

##
#   Import utility functions
##

. cpu-monitoring.sh

##
#   Define utility functions
##

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
        cd "${KITES_HOME}/pod-shared/"
        rm -rf *
        log_debug "Removed all file inside ${KITES_HOME}/pod-shared/"
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
    log_debug "Create single-pod."
    kubectl apply -n ${KITES_NAMSPACE_NAME} -f ${KITES_HOME}/kubernetes/net-test-single-pod.yaml
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
        declare -xg "POD_NAME_$pod_index"=$(_jq '.metadata.name')
        declare pod_name=POD_NAME_$pod_index
        echo "POD_NAME_"$pod_index"="${!pod_name}"" >>${KITES_HOME}/pod-shared/pods_nodes.env

        log_debug "Obtaining pod IPv4. pod number $pod_index."
        declare -xg "POD_IP_$pod_index=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test" -o json | jq -r ".items[$pod_index-1].status.podIPs[0].ip")"
        declare ip_name=POD_IP_$pod_index
        echo "${!ip_name}"
        echo "POD_IP_"$pod_index"="${!ip_name}"" >>${KITES_HOME}/pod-shared/pods_nodes.env
        ip_parsed_pods=$(sed -e "s/\./, /g" <<<${!ip_name})
        declare -xg "IP_$pod_index= $ip_parsed_pods"

        log_debug "Obtaining pod IPv6. pod number $pod_index."
        declare -xg "POD_IP6_$pod_index=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test" -o json | jq -r ".items[$pod_index-1].status.podIPs[1].ip")"
        declare ip6_name=POD_IP6_$pod_index
        echo "POD_IP6_$pod_index="${!ip6_name}"" >>${KITES_HOME}/pod-shared/pods_nodes.env

        log_debug "Obtaining pod nodeName. pod number $pod_index."
        declare -xg "POD_HOSTNAME_$pod_index=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test" -o json | jq -r ".items[$pod_index-1].spec.nodeName")"
        declare pod_hostname=POD_HOSTNAME_$pod_index
        echo "POD_HOSTNAME_$pod_index=${!pod_hostname}">> ${KITES_HOME}/pod-shared/pods_nodes.env
        log_debug "Obtaining pod MAC. pod number $pod_index."
        declare pod_name=POD_NAME_$pod_index
        mac_pod=$(kubectl -n ${KITES_NAMSPACE_NAME} exec -i "${!pod_name}" -- bash -c "${KITES_HOME}/scripts/linux/get-mac-address-pod.sh")
        declare -xg "MAC_ADDR_POD_$pod_index=$mac_pod"
        #echo "MAC_ADDR_POD_$pod_index=$mac_pod">> ${KITES_HOME}/pod-shared/pods_nodes.env
        echo "Name: ${!pod_name}, IPv4: ${!ip_name}, MAC: $mac_pod"
        ((pod_index++))
    done

    log_debug "Obtaining the names, IPs, MAC Addresse of the SinglePOD."
    declare -xg "SINGLE_POD_NAME=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test-single-pod" -o jsonpath="{.items[0].metadata.name}")"
    echo "SINGLE_POD_NAME="$SINGLE_POD_NAME"" >>${KITES_HOME}/pod-shared/pods_nodes.env
    declare -xg "MAC_ADDR_SINGLE_POD=$(kubectl exec -n ${KITES_NAMSPACE_NAME} -i $SINGLE_POD_NAME -- bash -c "${KITES_HOME}/scripts/linux/single-pod-get-mac-address.sh")"
    #echo "MAC_ADDR_SINGLE_POD="$MAC_ADDR_SINGLE_POD"">> ${KITES_HOME}/pod-shared/pods_nodes.env
    declare -xg "SINGLE_POD_IP=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test-single-pod" -o jsonpath="{.items[0].status.podIPs[0].ip}")"
    echo "SINGLE_POD_IP=$SINGLE_POD_IP" >>${KITES_HOME}/pod-shared/pods_nodes.env
    declare -xg "IP_PARSED_SINGLE_POD=$(sed -e "s/\./, /g" <<<${SINGLE_POD_IP})"
    #echo "IP_PARSED_SINGLE_POD="$IP_PARSED_SINGLE_POD"">> ${KITES_HOME}/pod-shared/pods_nodes.env
    declare -xg "SINGLE_POD_IP6=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test-single-pod" -o jsonpath="{.items[0].status.podIPs[1].ip}")"
    echo "SINGLE_POD_IP6="$SINGLE_POD_IP6"" >>${KITES_HOME}/pod-shared/pods_nodes.env
    declare -xg "SINGLE_POD_HOSTNAME=$(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test-single-pod" -o json | jq -r ".items[0].spec.nodeName")"
    echo "SINGLE_POD_HOSTNAME="$SINGLE_POD_HOSTNAME"" >>${KITES_HOME}/pod-shared/pods_nodes.env

    log_debug "Obtaining the names, IPs, MAC Addresse of  worker nodes."
    for row in $(kubectl get nodes --selector='!node-role.kubernetes.io/master' -o json | jq -r ".items[] | @base64"); do
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }
        log_debug "Obtaining node name. node number $node_index."
        declare -xg "NODE_NAME_$node_index"=$(_jq '.metadata.name')
        declare node_name=NODE_NAME_$node_index
        echo "NODE_NAME_"$node_index"="${!node_name}"" >>${KITES_HOME}/pod-shared/pods_nodes.env

        for addr in $(kubectl get nodes ${!node_name} -o json | jq -r ".status.addresses[] | @base64"); do
            _jqa() {
                echo ${addr} | base64 --decode | jq -r ${1}
            }
            if [ "$(_jqa '.type')" == "InternalIP" ]; then
                declare -xg "NODE_IP_$node_index"="$(_jqa '.address')"
                declare node_ip=NODE_IP_$node_index
                echo "NODE_IP_$node_index="${!node_ip}"" >>${KITES_HOME}/pod-shared/pods_nodes.env
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

    initialize_pods "$RUN_TEST_SAMENODE"
    create_pod_list
    get_pods_info
    if $RUN_TEST_UDP; then
        # TODO refactoring this script
        ${KITES_HOME}/scripts/linux/create-udp-traffic.sh $CNI $N $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF
    fi
}

function exec_tcp_test_between_pods() {
    log_inf "Start execution TCP net test between pods."
    ID_EXP=$1
    TCP_TEST="TCP"
    cd "${KITES_HOME}/pod-shared"

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
            if $RUN_TEST_CPU; then
                if [ "$i" -eq "$j" ] && $RUN_TEST_SAME; then
                    start_cpu_monitor_nodes "$N" "SAMEPOD: ${!name1_pod//[$' ']/}" 10 $TCP_TEST
                elif [ "${!host1_pod}" != "${!host2_pod}" ] && $RUN_TEST_DIFF; then
                    start_cpu_monitor_nodes "$N" "DIFFERENTNODES: ${!host1_pod//[$' ']/} TO ${!host2_pod//[$' ']/}" 10 $TCP_TEST
                fi
            fi
            kubectl -n ${KITES_NAMSPACE_NAME} exec -i ${!name1_pod} -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"${!ip1_pod}\" \"${!ip2_pod}\" \"${!host1_pod}\" \"${!host2_pod}\" \"${!name1_pod}\" \"${!name2_pod}\" $ID_EXP"
        done
        if ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" = "${!host1_pod//[$' ']/}" ] && $RUN_TEST_SAMENODE) || ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" != "${!host1_pod//[$' ']/}" ] && $RUN_TEST_DIFF); then
            if $RUN_TEST_CPU; then
                start_cpu_monitor_nodes "$N" "SINGLEPOD TO ${!name1_pod//[$' ']/}" 10 $TCP_TEST
            fi

            if [ "$RUN_IPV4_ONLY" == "true" ]; then
                declare single_pod_ip="SINGLE_POD_IP"
            elif [ "$RUN_IPV6_ONLY" == "true" ]; then
                declare single_pod_ip="SINGLE_POD_IP6"
            fi
            kubectl -n ${KITES_NAMSPACE_NAME} exec -i ${!name1_pod} -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"${!ip1_pod}\" \"${!single_pod_ip}\" \"${!host1_pod}\" \"$SINGLE_POD_HOSTNAME\" \"${!name1_pod}\" \"$SINGLE_POD_NAME\" $ID_EXP"
        fi
    done
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
    ID_EXP=exp-1 # TODO make it configurable

    if $UDP_TEST; then
        for ((pps = 10000; pps <= 100000; pps += 10000)); do
            ${KITES_HOME}/scripts/linux/udp-test.sh "$pps" 1000 "$ID_EXP" "$N" "$RUN_TEST_SAME" "$RUN_TEST_SAMENODE" "$RUN_TEST_DIFF" "$RUN_TEST_CPU"
            ${KITES_HOME}/scripts/linux/merge-udp-test.sh "$pps" 1000 "$N"
        done
    fi

    ###TCP TEST FOR PODS AND NODES WITH IPERF3
    if $TCP_TEST; then
        cd "${KITES_HOME}/pod-shared"
        echo -e "TCP TEST\n" >TCP_IPERF_OUTPUT.txt
        exec_tcp_test_between_pods "$ID_EXP" "$N" "$RUN_TEST_SAME" "$RUN_TEST_SAMENODE" "$RUN_TEST_DIFF" "$RUN_TEST_CPU"

        echo -e "TCP TEST NODES\n" >TCP_IPERF_NODE_OUTPUT.txt
        for ((minion_n = 1; minion_n <= "$N"; minion_n++)); do
            declare node_ip="NODE_IP_$minion_n"
            if [ "$RUN_IPV4_ONLY" == "true" ]; then
                declare version="4"
            elif [ "$RUN_IPV6_ONLY" == "true" ]; then
                declare version="6"
            fi
            sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-"${minion_n}".k8s-play.local "${KITES_HOME}/scripts/linux/tcp-test-node.sh $ID_EXP $N ${!node_ip} $version"
        done
    fi
}

function parse_test() {
    log_inf "Start parsing test results."
    CNI=$1
    N=$2
    TCP_TEST=$3
    UDP_TEST=$4

    if [ ! -d "${KITES_HOME}/pod-shared/tests/$CNI" ]; then
        log_debug "Directory ${KITES_HOME}/pod-shared/tests/$CNI doesn't exists."
        log_debug "Creating: Directory ${KITES_HOME}/pod-shared/tests/$CNI"
        mkdir -p "${KITES_HOME}/pod-shared/tests/$CNI"
    fi

    cd "${KITES_HOME}/pod-shared/tests/$CNI"

    if $UDP_TEST; then
        echo "CNI, TEST_TYPE, ID_EXP, BYTE, PPS, VM_SRC, VM_DEST, POD_SRC, POD_DEST, IP_SRC, IP_DEST, OUTGOING, INCOMING, PASSED, TX_TIME, RX_TIME, TIMESTAMP, CONFIG, CONFIG_CODE" >netsniff-tests.csv
        echo "OUTGOING, TX_TIME, VM_SRC, VM_DEST, POD_SRC, POD_DEST, PPS" >trafgen-tests.csv

        # CNI | Tipo di test | ID_EXP | PPS | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time | TIMESTAMP
        for ((pps = 10000; pps <= 100000; pps += 10000)); do
            ${KITES_HOME}/scripts/linux/parse-netsniff-test.sh "$CNI" ${KITES_HOME}/pod-shared/NETSNIFF-1000byte-${pps}pps.txt ${KITES_HOME}/pod-shared/TRAFGEN-1000byte-${pps}pps.txt "$N"
        done

        ${KITES_HOME}/scripts/linux/compute-udp-results.sh netsniff-tests.csv
        ${KITES_HOME}/scripts/linux/compute-udp-throughput.sh udp_results.csv
    fi

    if $TCP_TEST; then
        echo "CNI, TEST_TYPE, ID_EXP, VM_SRC, VM_DEST, POD_SRC, POD_DEST, IP_SRC, IP_DEST, OUTGOING, OUT_UNIT, INCOMING, INC_UNIT, THROUGHPUT, THR_UNIT, TX_TIME, RX_TIME, TIMESTAMP" >iperf-tests.csv
        #TCP TEST FOR PODS AND NODES WITH IPERF3
        ${KITES_HOME}/scripts/linux/parse-iperf-test.sh "$CNI" "${KITES_HOME}/pod-shared/TCP_IPERF_OUTPUT.txt" "$N"
        ${KITES_HOME}/scripts/linux/parse-iperf-test-node.sh "$CNI" "${KITES_HOME}/pod-shared/TCP_IPERF_NODE_OUTPUT.txt" "$N"
    fi

    log_debug "Removing contents inside ${KITES_HOME}/tests/"
    rm -rf "${KITES_HOME}/tests/${CNI}"

    if [ ! -d "${KITES_HOME}/tests/" ]; then
        log_debug "Directory ${KITES_HOME}/tests/ doesn't exists."
        log_debug "Creating: Directory ${KITES_HOME}/tests/"
        mkdir -p ${KITES_HOME}/tests/
    fi

    log_debug "Moving results in ${KITES_HOME}/tests/"
    mv "${KITES_HOME}/pod-shared/tests/${CNI}" "${KITES_HOME}/tests/"

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
    log_debug " RUN_TEST_CPU=${RUN_TEST_CPU}"
    log_debug " CLEAN_ALL=${CLEAN_ALL}"
    log_debug " IPv6DualStack=${IPv6DualStack}"
    log_debug " RUN_IPV4_ONLY=${RUN_IPV4_ONLY}"
    log_debug " RUN_IPV6_ONLY=${RUN_IPV6_ONLY}"
    log_debug " VERBOSITY_LEVEL=${VERBOSITY_LEVEL}"
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
        RUN_TEST_SAME="false"
        RUN_TEST_SAMENODE="false"
        RUN_TEST_DIFF="false"
        for i in $(awk '{gsub(/,/," ");print}' <<<"$2"); do
            case $i in
            all)
                RUN_TEST_SAME="true"
                RUN_TEST_SAMENODE="true"
                RUN_TEST_DIFF="true"
                ;;
            samepod)
                RUN_TEST_SAME="true"
                ;;
            samenode)
                RUN_TEST_SAMENODE="true"
                ;;
            diffnode)
                RUN_TEST_DIFF="true"
                ;;
            *) error "Invalid argument: $1\n" && display_usage && exit ;;
            esac
        done
        ;;
    --nocpu | -nc)
        RUN_TEST_CPU="false"
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
fi

if [ "$CNI" = "" ]; then
    display_usage && exit
fi
print_all_setup_parameters
start=$(date +%s)
log_inf "KITES start."

if $RUN_TEST_CPU; then
    start_cpu_monitor_nodes "$N" "IDLE" 10 "IDLE"
fi

create_name_space

initialize_net_test "$CNI" "$N" $RUN_TEST_UDP $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF

exec_net_test "$N" $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF $RUN_TEST_CPU
parse_test "$CNI" "$N" $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_CPU

end=$(date +%s)
log_inf "KITES stop. Execution time was $(expr "$end" - "$start") seconds."
log_debug "Carla is a killer of VMs."
