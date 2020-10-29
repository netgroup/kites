#!/bin/bash
sudo apt install -y sshpass
N=$1
echo "numbero minion_n=$N"
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
	sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-${minion_n}.k8s-play.local "/vagrant/ext/kites/scripts/linux/start-cpu-monitoring.sh" 
done