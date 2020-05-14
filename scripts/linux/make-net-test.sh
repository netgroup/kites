#!/bin/bash
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
/vagrant/ext/kites/scripts/linux/udp-test.sh 1000 100 $ID_EXP
/vagrant/ext/kites/scripts/linux/udp-test.sh 1000 1000 $ID_EXP
/vagrant/ext/kites/scripts/linux/udp-test.sh 10000 100 $ID_EXP
/vagrant/ext/kites/scripts/linux/udp-test.sh 10000 1000 $ID_EXP
/vagrant/ext/kites/scripts/linux/udp-test.sh 20000 100 $ID_EXP
/vagrant/ext/kites/scripts/linux/udp-test.sh 50000 100 $ID_EXP
/vagrant/ext/kites/scripts/linux/udp-test.sh 20000 1000 $ID_EXP
/vagrant/ext/kites/scripts/linux/udp-test.sh 50000 1000 $ID_EXP
/vagrant/ext/kites/scripts/linux/udp-test.sh 100000 100 $ID_EXP
/vagrant/ext/kites/scripts/linux/udp-test.sh 100000 1000 $ID_EXP

/vagrant/ext/kites/scripts/linux/merge-udp-test.sh 1000 100
/vagrant/ext/kites/scripts/linux/merge-udp-test.sh 1000 1000
/vagrant/ext/kites/scripts/linux/merge-udp-test.sh 10000 100
/vagrant/ext/kites/scripts/linux/merge-udp-test.sh 10000 1000
/vagrant/ext/kites/scripts/linux/merge-udp-test.sh 20000 100 
/vagrant/ext/kites/scripts/linux/merge-udp-test.sh 50000 100 
/vagrant/ext/kites/scripts/linux/merge-udp-test.sh 20000 1000
/vagrant/ext/kites/scripts/linux/merge-udp-test.sh 50000 1000
/vagrant/ext/kites/scripts/linux/merge-udp-test.sh 100000 100
/vagrant/ext/kites/scripts/linux/merge-udp-test.sh 100000 1000

#TCP TEST FOR PODS AND NODES WITH IPERF3
echo -e "TCP TEST\n" > TCP_IPERF_OUTPUT.txt
/vagrant/ext/kites/scripts/linux/tcp-test.sh $ID_EXP
echo -e "TCP TEST NODES\n" > TCP_IPERF_NODE_OUTPUT.txt
sudo apt-get install -y sshpass
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-1.k8s-play.local "/vagrant/ext/kites/scripts/linux/tcp-test-node.sh $ID_EXP"
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-2.k8s-play.local "/vagrant/ext/kites/scripts/linux/tcp-test-node.sh $ID_EXP"
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-3.k8s-play.local "/vagrant/ext/kites/scripts/linux/tcp-test-node.sh $ID_EXP"
