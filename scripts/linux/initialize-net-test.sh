#!/bin/bash
CNI=$1
N=$2
RUN_TEST_UDP=$3
RUN_TEST_SAME=$4
RUN_TEST_SAMENODE=$5
RUN_TEST_DIFF=$6
shift 6
bytes=("$@")
/vagrant/ext/kites/scripts/linux/initialize-pods.sh $RUN_TEST_SAMENODE
/vagrant/ext/kites/scripts/linux/create-pods-list.sh
if $RUN_TEST_UDP
then
    /vagrant/ext/kites/scripts/linux/create-udp-traffic.sh $CNI $N $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF "${bytes[@]}"
fi