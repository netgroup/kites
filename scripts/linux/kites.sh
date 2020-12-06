#!/bin/bash
. utils/logging.sh
. utils/check-dependencies.sh

function display_usage() {
    echo "Kites is a plugin of kubernetes-playground."
    echo "This script must be run on the master node."
    echo -e "\nUsage: $0 --cni <cni conf. name> [Optional arguments] \n"
    echo "Mandatory arguments:"
    echo "  --cni     : set the name of the CNI configuration ex: weavenet, calicoIPIP, calicoVXLAN, flannel"
    echo "  --nodes   : set the number of nodes in the cluster"
    echo "Optional arguments:"
    echo "  --nodes  : set the number of nodes in the cluster. Default set =2"
    echo "   -h       : display this help message"
}

[ "$1" = "" ] && display_usage && exit

N=2
RUN_TEST_TCP="true"
RUN_TEST_UDP="true"
RUN_TEST_SAME="true"
RUN_TEST_SAMENODE="true"
RUN_TEST_DIFF="true"
RUN_TEST_CPU="true"

while [ $# -gt 0 ]; do
    arg=$1
    case $arg in
    --cni)
        CNI=$2
        ;;
    --nodes)
        N=$2
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
    --configurations | -config)
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

echo $CNI $N
start=$(date +%s)
log_inf "KITES start."

if $RUN_TEST_CPU; then
    #/vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "IDLE" 10 "IDLE"
    TEST_TYPE="IDLE"
    DURATION=10
    CPU_TEST="IDLE"
    echo "cpu from master"
    /vagrant/ext/kites/scripts/linux/start-cpu-monitoring.sh "$TEST_TYPE" $DURATION $CPU_TEST
    echo "numero minion_n=$N"
    echo $TEST_TYPE
    for ((minion_n = 1; minion_n <= $N; minion_n++)); do
        sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-${minion_n}.k8s-play.local "/vagrant/ext/kites/scripts/linux/start-cpu-monitoring.sh \"$TEST_TYPE\" $DURATION \"$CPU_TEST\""
        log_inf "started minion $minion_n"
    done
fi

end=$(date +%s)
log_inf "KITES stop. Execution time was $(expr $end - $start) seconds."
