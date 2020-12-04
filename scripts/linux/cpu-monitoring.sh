#!/bin/bash

N=$1
TEST_TYPE=$2
DURATION=$3
CPU_TEST=$4
echo "cpu from master"
/vagrant/ext/kites/scripts/linux/start-cpu-monitoring.sh "$TEST_TYPE" $DURATION $CPU_TEST
echo "numero minion_n=$N"
echo $TEST_TYPE
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
	sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-${minion_n}.k8s-play.local "/vagrant/ext/kites/scripts/linux/start-cpu-monitoring.sh \"$TEST_TYPE\" $DURATION \"$CPU_TEST\""  
done