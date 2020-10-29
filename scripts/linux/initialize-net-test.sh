#!/bin/bash
CNI=$1
N=$2
/vagrant/ext/kites/scripts/linux/initialize-pods.sh
/vagrant/ext/kites/scripts/linux/create-pods-list.sh
/vagrant/ext/kites/scripts/linux/create-udp-traffic.sh $CNI $N
