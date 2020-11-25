#!/bin/bash
CNI=$1
N=$2
RUN_TEST_UDP=$3
/vagrant/ext/kites/scripts/linux/initialize-pods.sh
/vagrant/ext/kites/scripts/linux/create-pods-list.sh
if $RUN_TEST_UDP
then
    /vagrant/ext/kites/scripts/linux/create-udp-traffic.sh $CNI $N
fi