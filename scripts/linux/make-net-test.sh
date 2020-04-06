#!/bin/sh
#UDP TEST FOR PODS WITH NETSNIFF
/vagrant/ext/kites/scripts/linux/udp-test.sh 1000 100
/vagrant/ext/kites/scripts/linux/udp-test.sh 1000 1000
/vagrant/ext/kites/scripts/linux/udp-test.sh 10000 100
/vagrant/ext/kites/scripts/linux/udp-test.sh 10000 1000
/vagrant/ext/kites/scripts/linux/udp-test.sh 100000 100
/vagrant/ext/kites/scripts/linux/udp-test.sh 100000 1000

#TCP TEST FOR PODS AND MASTER NODE WITH IPERF3
#/vagrant/ext/kites/scripts/linux/tcp-test.sh
