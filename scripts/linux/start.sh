#!/bin/bash
CNI=$1
N=$2
/vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N 
/vagrant/ext/kites/scripts/linux/initialize-net-test.sh $CNI $N
/vagrant/ext/kites/scripts/linux/make-net-test.sh $N
/vagrant/ext/kites/scripts/linux/parse-test.sh $CNI
echo -e "\n ### REMOVE FILE IN 5 MINUTES ### \n"
sleep 5m
/vagrant/ext/kites/scripts/linux/remove-all.sh
