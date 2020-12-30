#!/bin/bash
CNI=$1
N=$2
TCP_TEST=$3
UDP_TEST=$4
shift 4
bytes=("$@")

if [ -d "/vagrant/ext/kites/pod-shared/tests/$CNI" ] 
then
    cd /vagrant/ext/kites/pod-shared/tests/$CNI
else
    echo "Directory /vagrant/ext/kites/pod-shared/tests/$CNI doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/pod-shared/tests/$CNI"
    mkdir -p /vagrant/ext/kites/pod-shared/tests/$CNI && cd /vagrant/ext/kites/pod-shared/tests/$CNI
fi

if $UDP_TEST
then
    echo "CNI, TEST_TYPE, ID_EXP, BYTE, PPS, VM_SRC, VM_DEST, POD_SRC, POD_DEST, IP_SRC, IP_DEST, OUTGOING, INCOMING, PASSED, TX_TIME, RX_TIME, TIMESTAMP, CONFIG, CONFIG_CODE" > netsniff-tests.csv
    echo "OUTGOING, TX_TIME, VM_SRC, VM_DEST, POD_SRC, POD_DEST, PPS" > trafgen-tests.csv
    
    # CNI | Tipo di test | ID_EXP | PPS | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time | TIMESTAMP
    # bytes=(100 1000)
    for byte in "${bytes[@]}"
    do
        for (( pps=16800; pps<=19200; pps+=100 ))
        do
            /vagrant/ext/kites/scripts/linux/parse-netsniff-test.sh $CNI /vagrant/ext/kites/pod-shared/NETSNIFF-${byte}byte-${pps}pps.txt /vagrant/ext/kites/pod-shared/TRAFGEN-${byte}byte-${pps}pps.txt $N
        done
    done
    
    /vagrant/ext/kites/scripts/linux/compute-udp-results.sh netsniff-tests.csv $CNI ${bytes[@]}
    for byte in "${bytes[@]}"
    do
        /vagrant/ext/kites/scripts/linux/compute-udp-throughput.sh udp_results_${CNI}_${byte}bytes.csv $CNI $byte
    done
fi

if $TCP_TEST
then
    echo "CNI, TEST_TYPE, ID_EXP, VM_SRC, VM_DEST, POD_SRC, POD_DEST, IP_SRC, IP_DEST, OUTGOING, OUT_UNIT, INCOMING, INC_UNIT, THROUGHPUT, THR_UNIT, TX_TIME, RX_TIME, TIMESTAMP" > iperf-tests.csv
    #TCP TEST FOR PODS AND NODES WITH IPERF3
    /vagrant/ext/kites/scripts/linux/parse-iperf-test.sh $CNI "/vagrant/ext/kites/pod-shared/TCP_IPERF_OUTPUT.txt" $N
    /vagrant/ext/kites/scripts/linux/parse-iperf-test-node.sh $CNI "/vagrant/ext/kites/pod-shared/TCP_IPERF_NODE_OUTPUT.txt" $N
fi

if [ -d "/vagrant/ext/kites/tests/" ] 
then
    mv /vagrant/ext/kites/pod-shared/tests/$CNI /vagrant/ext/kites/tests/
else
    echo "Directory /vagrant/ext/kites/tests/ doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/tests/"
    mkdir -p /vagrant/ext/kites/tests/
    mv /vagrant/ext/kites/pod-shared/tests/$CNI /vagrant/ext/kites/tests/
fi