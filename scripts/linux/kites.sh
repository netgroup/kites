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
    echo "   -h       : display this help message"
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
VERBOSITY_LEVEL=5 # default debug level. see in utils/logging.sh

##
#   Import utility functions
##

. cpu-monitoring.sh

##
#   Define utility functions
##

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
    kubectl delete daemonset net-test-ds
    log_debug "Delete pods net-test-single-pod"
    kubectl delete pods net-test-single-pod
    #clean_pod_shared_dir
}

function create_pod_list() {
    if [ ! -d "${KITES_HOME}/pod-shared/" ]; then
        log_debug "Directory ${KITES_HOME}/pod-shared/ doesn't exists."
        log_debug "Creating: Directory ${KITES_HOME}/pod-shared/"
        mkdir -p ${KITES_HOME}/pod-shared/
    fi
    kubectl get pod -o wide >${KITES_HOME}/pod-shared/podList.txt
    awk '{ print $1, $6, $7}' ${KITES_HOME}/pod-shared/podList.txt >${KITES_HOME}/pod-shared/podNameAndIP.txt
}

function initialize_pods() {
    log_inf "Initialize pods."
    RUN_TEST_SAMENODE=$1
    #creazione daemonset
    log_debug "Create demonset."
    kubectl apply -f ${KITES_HOME}/kubernetes/net-test-dev_ds.yaml
    log_debug "Wait 60 sec."
    sleep 60
    #creazione single-pod
    if $RUN_TEST_SAMENODE; then
        log_debug "Create single-pod."
        kubectl apply -f ${KITES_HOME}/kubernetes/net-test-single-pod.yaml
        log_debug "Wait 30 sec."
        sleep 30
    fi
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
        echo "Benchmark will run only following configuration: ${1}"
        ;;
    --nocpu | -nc)
        #shift
        RUN_TEST_CPU="false"
        echo "Benchmark will run only following configuration: ${1}"
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

initialize_net_test $CNI $N $RUN_TEST_UDP $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF

/vagrant/ext/kites/scripts/linux/make-net-test.sh $N $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF $RUN_TEST_CPU
/vagrant/ext/kites/scripts/linux/parse-test.sh $CNI $N $RUN_TEST_TCP $RUN_TEST_UDP $RUN_TEST_CPU

end=$(date +%s)
log_inf "KITES stop. Execution time was $(expr $end - $start) seconds."
log_debug "Carla is a killer of VMs."
