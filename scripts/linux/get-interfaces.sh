#!/bin/bash
cd /vagrant/ext/kites/pod-shared
POD_NAME_1=$(awk 'NR==2 { print $1}' podNameAndIP.txt)
POD_NAME_2=$(awk 'NR==3 { print $1}' podNameAndIP.txt)
POD_NAME_3=$(awk 'NR==4 { print $1}' podNameAndIP.txt)
sudo yum install -y sshpass
echo "MASTER" > interfaces.txt
ip a >> interfaces.txt
echo -e "\n MINION 1 \n" >> interfaces.txt
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-1.k8s-play.local "/sbin/ip a" >> interfaces.txt
echo -e "\n MINION 2 \n" >> interfaces.txt
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-2.k8s-play.local "/sbin/ip a" >> interfaces.txt
echo -e "\n MINION 3 \n" >> interfaces.txt
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-3.k8s-play.local "/sbin/ip a" >> interfaces.txt

echo -e "\n POD 1 \n" >> interfaces.txt
kubectl exec -it $POD_NAME_1 -- bash -c "ip a" >> interfaces.txt
echo -e "\n POD 2 \n" >> interfaces.txt
kubectl exec -it $POD_NAME_2 -- bash -c "ip a" >> interfaces.txt
echo -e "\n POD 3 \n" >> interfaces.txt
kubectl exec -it $POD_NAME_3 -- bash -c "ip a" >> interfaces.txt

