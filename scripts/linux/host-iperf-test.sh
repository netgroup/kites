#!/bin/bash
sudo apt-get install -y sshpass iperf3
COMMAND="/vagrant/ext/kites/scripts/linux/get-host-eth0-ip.sh"
IP_WORKER_1=$(sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-1.k8s-play.local "$COMMAND")
IP_WORKER_2=$(sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-2.k8s-play.local "$COMMAND")
IP_WORKER_3=$(sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-3.k8s-play.local "$COMMAND")
echo -e "iperf3 -c ${IP_WORKER_1} \n\n"
iperf3 -c $IP_WORKER_1
echo -e "iperf3 -c ${IP_WORKER_2} \n\n"
iperf3 -c $IP_WORKER_2
echo -e "iperf3 -c ${IP_WORKER_3} \n\n"
iperf3 -c $IP_WORKER_3
