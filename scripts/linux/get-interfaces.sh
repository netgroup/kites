#!/bin/bash
cd /vagrant/ext/kites/pod-shared
POD_NAME_1=$(awk 'NR==2 { print $1}' podNameAndIP.txt)
POD_NAME_2=$(awk 'NR==3 { print $1}' podNameAndIP.txt)
POD_NAME_3=$(awk 'NR==4 { print $1}' podNameAndIP.txt)
sudo yum install -y sshpass
echo -e "### MINION 1 ###\n" > interfaces-routes.txt
ip a >> interfaces-routes.txt
printf '\n' >> interfaces-routes.txt
ip r >> interfaces-routes.txt
echo -e "\n ### MINION 1 ###\n" >> interfaces-routes.txt
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-1.k8s-play.local "/sbin/ip a && printf '\n' && /sbin/ip r" >> interfaces-routes.txt

echo -e "\n ### MINION 2 ###\n" >> interfaces-routes.txt
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-2.k8s-play.local "/sbin/ip a && printf '\n' && /sbin/ip r" >> interfaces-routes.txt
echo -e "\n ### MINION 3 ###\n" >> interfaces-routes.txt
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-3.k8s-play.local "/sbin/ip a && printf '\n' && /sbin/ip r" >> interfaces-routes.txt

echo -e "\n ### POD 1 ###\n" >> interfaces-routes.txt
kubectl exec -it $POD_NAME_1 -- bash -c "ip a && printf '\n' && ip r" >> interfaces-routes.txt
echo -e "\n ### POD 2 ###\n" >> interfaces-routes.txt
kubectl exec -it $POD_NAME_2 -- bash -c "ip a && printf '\n' && ip r" >> interfaces-routes.txt
echo -e "\n ### POD 3 ###\n" >> interfaces-routes.txt
kubectl exec -it $POD_NAME_3 -- bash -c "ip a && printf '\n' && ip r" >> interfaces-routes.txt

