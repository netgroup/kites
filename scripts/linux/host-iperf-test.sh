#!/bin/bash
sudo apt-get install -y sshpass iperf3
COMMAND="/vagrant/ext/kites/scripts/linux/get-host-eth0-ip.sh"
for (( minion_n=1; minion_n<=$N; minion_n++ ))
   do
    IP_WORKER_$minion_n=$(sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-$minon_n.k8s-play.local "$COMMAND")
done
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
    declare ip_worker="IP_WORKER_$minion_n"
    echo -e "iperf3 -c ${!ip_worker} \n\n"
    iperf3 -c ${!ip_worker}
done