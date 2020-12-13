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
    echo "  --dual-stack        : use IPv4 and IPv6 if enabled."
    echo "  -4                  : use IPv4q only."
    echo "  -6                  : use IPv6 only."
    echo "  -h                  : display this help message"
}

[ "$1" = "" ] && display_usage && exit

##
#   Deafult parameters
##

KITES_HOME="/vagrant/ext/kites"
KITES_NAMSPACE_NAME="kites"
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
    log_debug "Obtaining the names, IPs, MAC Addresse of the DaemonSet."
    pod_index=1

    for row in $(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test" -o json | jq -r ".items[] | @base64"); do
        # most of the info are available from here
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }
        log_debug "Obtaining pod name. pod number $pod_index."
        declare -xg "POD_$pod_index"=$(_jq '.metadata.name')

        log_debug "Obtaining pod IPv4. pod number $pod_index."
        declare -xg "POD_IP_$pod_index= $(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test" -o json | jq -r ".items[$pod_index-1].status.podIPs[0].ip")"
        declare ip_name=POD_IP_$pod_index
        ip_parsed_pods=$(sed -e "s/\./, /g" <<<${!ip_name})
        declare -xg "IP_$pod_index= $ip_parsed_pods"
        log_debug "Obtaining pod IPv6. pod number $pod_index."
        declare -xg "POD_IP6_$pod_index= $(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test" -o json | jq -r ".items[$pod_index-1].status.podIPs[1].ip")"

        log_debug "Obtaining pod nodeName. pod number $pod_index."
        declare -xg "VM_NAME_$pod_index= $(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test" -o json | jq -r ".items[$pod_index-1].spec.nodeName")"

        declare pod_names=POD_$pod_index
        mac_pod=$(kubectl -n ${KITES_NAMSPACE_NAME} exec -i "${!pod_names}" -- bash -c "${KITES_HOME}/scripts/linux/get-mac-address-pod.sh")
        declare -xg "MAC_ADDR_POD_$pod_index=$mac_pod"
        echo $mac_pod
        ((pod_index++))
    done

    
    declare -xg "POD= $(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test-single-pod" -o jsonpath="{.items[0].metadata.name}" )"
    declare -xg "MAC_ADDR_SINGLE_POD= $(kubectl exec -n ${KITES_NAMSPACE_NAME} -i $POD -- bash -c "${KITES_HOME}/scripts/linux/single-pod-get-mac-address.sh")"
    declare -xg "IP_PARSED_SINGLE_POD= $(kubectl exec -n ${KITES_NAMSPACE_NAME} -i $POD -- bash -c "${KITES_HOME}/scripts/linux/single-pod-get-ip.sh")"
    declare -xg "single_pod_vm= $(kubectl get pods -n ${KITES_NAMSPACE_NAME} --selector=app="net-test-single-pod" -o json | jq -r ".items[0].spec.nodeName")"


}

function initialize_net_test() {
    log_inf "Initialize net test."
    CNI=$1
    N=$2
    RUN_TEST_UDP=$3
    RUN_TEST_SAME=$4
    RUN_TEST_SAMENODE=$5
    RUN_TEST_DIFF=$6

    initialize_pods $RUN_TEST_SAMENODE
    create_pod_list
    get_pods_info

    if $RUN_TEST_UDP; then
        # TODO refactoring this script
        /vagrant/ext/kites/scripts/linux/create-udp-traffic.sh $CNI $N $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF
    fi
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

##
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
    start_cpu_monitor_nodes $N "IDLE" 10 "IDLE"
fi

create_name_space

initialize_net_test $CNI $N $RUN_TEST_UDP $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF

# /vagrant/ext/kites/scripts/linux/make-net-test.sh $N $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF $RUN_TEST_CPU
# /vagrant/ext/kites/scripts/linux/parse-test.sh $CNI $N $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_CPU

end=$(date +%s)
log_inf "KITES stop. Execution time was $(expr $end - $start) seconds."
log_debug "Carla is a killer of VMs."
