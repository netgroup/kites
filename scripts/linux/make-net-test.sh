#!/bin/bash
N=$1
TCP_TEST=$2
UDP_TEST=$3
RUN_TEST_SAME=$4
RUN_TEST_SAMENODE=$5
RUN_TEST_DIFF=$6

if [ -d "/vagrant/ext/kites/pod-shared/" ] 
then
    cd /vagrant/ext/kites/pod-shared/
else
    echo "Directory /vagrant/ext/kites/pod-shared/ doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/pod-shared/"
    mkdir -p /vagrant/ext/kites/pod-shared/ && cd /vagrant/ext/kites/pod-shared/
fi
ID_EXP=exp-1

#UDP TEST FOR PODS WITH NETSNIFF
if $UDP_TEST
then
    for (( pps=10000; pps<=60000; pps+=5000 ))
    do
        /vagrant/ext/kites/scripts/linux/udp-test.sh $pps 1000 $ID_EXP $N $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF
        /vagrant/ext/kites/scripts/linux/merge-udp-test.sh $pps 1000 $N
    done
fi


###TCP TEST FOR PODS AND NODES WITH IPERF3
if $TCP_TEST
then
    echo -e "TCP TEST\n" > TCP_IPERF_OUTPUT.txt
    /vagrant/ext/kites/scripts/linux/tcp-test.sh $ID_EXP $N $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF

    echo -e "TCP TEST NODES\n" > TCP_IPERF_NODE_OUTPUT.txt
    sudo apt install -y sshpass
    for (( minion_n=1; minion_n<=$N; minion_n++ ))
    do
        sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-${minion_n}.k8s-play.local "/vagrant/ext/kites/scripts/linux/tcp-test-node.sh $ID_EXP $N"
    done
fi
