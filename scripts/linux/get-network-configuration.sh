#!/bin/bash
##TODO aggiungere ip link show type bridge sui minion
##TODO bridge link show cni0 -> per vedere tutte le porte associate a cni0

#according to the instructions in
#https://unix.stackexchange.com/questions/254419/how-to-get-a-deterministic-complete-dump-of-all-iptables-rules
#the commands to dump all iptables are:
#iptables -vL -t filter
#iptables -vL -t nat
#iptables -vL -t mangle
#iptables -vL -t raw
#iptables -vL -t security

cd /vagrant/ext/kites/pod-shared
POD_NAME_1=$(awk 'NR==2 { print $1}' podNameAndIP.txt)
POD_NAME_2=$(awk 'NR==3 { print $1}' podNameAndIP.txt)
POD_NAME_3=$(awk 'NR==4 { print $1}' podNameAndIP.txt)
sudo apt install -y sshpass
echo -e "###------------>>> MASTER <<<------------###" >network-configuration.txt
echo -e "\n---[IP Addresses]---\n" >>network-configuration.txt
ip a >>network-configuration.txt
echo -e "\n---[IP Routes]---\n" >>network-configuration.txt
ip r >>network-configuration.txt
echo -e "\n---[IP Link (show type bridge)]---\n" >>network-configuration.txt
ip link show type bridge >>network-configuration.txt
echo -e "\n---[Bridge Link]---\n" >>network-configuration.txt
bridge link >>network-configuration.txt
echo -e "\n---[Bridge Link (show dev cni0)]---\n" >>network-configuration.txt
bridge link show dev cni0 >>network-configuration.txt
echo -e "\n---[IP Tables]---\n" >>network-configuration.txt
sudo iptables -vL -t filter >>network-configuration.txt
sudo iptables -vL -t nat >>network-configuration.txt
sudo iptables -vL -t mangle >>network-configuration.txt
sudo iptables -vL -t raw >>network-configuration.txt
sudo iptables -vL -t security >>network-configuration.txt
echo -e "\n ###------------>>> MINION 1 <<<------------###" >>network-configuration.txt
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-1.k8s-play.local "printf '\n---[IP Addresses]--- \n' && \
																						  /sbin/ip a && \
																						  printf '\n---[IP Routes]--- \n' && \
																						  /sbin/ip r && \
																						  printf '\n---[IP Link (show type bridge)]--- \n' && \
																						  /sbin/ip link show type bridge && \
																						  printf '\n---[Bridge Link]--- \n' && \
																						  /sbin/bridge link && \
																						  printf '\n---[Bridge Link (show cni0)]--- \n' && \
																						  /sbin/bridge link show dev cni0 && \
																						  printf '\n---[IP Tables]--- \n' && \
																						  sudo iptables -vL -t filter && \
																						  sudo iptables -vL -t nat && \
																						  sudo iptables -vL -t mangle && \
																						  sudo iptables -vL -t raw && \
																						  sudo iptables -vL -t security \
																						  " >>network-configuration.txt
echo -e "\n ###------------>>> MINION 2 <<<------------###" >>network-configuration.txt
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-2.k8s-play.local "printf '\n---[IP Addresses]--- \n' && \
																						  /sbin/ip a && \
																						  printf '\n---[IP Routes]--- \n' && \
																						  /sbin/ip r && \
																						  printf '\n---[IP Link (show type bridge)]--- \n' && \
																						  /sbin/ip link show type bridge && \
																						  printf '\n---[Bridge Link]--- \n' && \
																						  /sbin/bridge link && \
																						  printf '\n---[Bridge Link (show dev cni0)]--- \n' && \
																						  /sbin/bridge link show dev cni0 && \
																						  printf '\n---[IP Tables]--- \n' && \
																						  sudo iptables -vL -t filter && \
																						  sudo iptables -vL -t nat && \
																						  sudo iptables -vL -t mangle && \
																						  sudo iptables -vL -t raw && \
																						  sudo iptables -vL -t security \
																						  " >>network-configuration.txt
echo -e "\n ###------------>>> MINION 3 <<<------------###" >>network-configuration.txt
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-3.k8s-play.local "printf '\n---[IP Addresses]--- \n' && \
																						  /sbin/ip a && \
																						  printf '\n---[IP Routes]--- \n' && \
																						  /sbin/ip r && \
																						  printf '\n---[IP Link (show type bridge)]--- \n' && \
																						  /sbin/ip link show type bridge && \
																						  printf '\n---[Bridge Link]--- \n' && \
																						  /sbin/bridge link && \
																						  printf '\n---[Bridge Link (show dev cni0)]--- \n' && \
																						  /sbin/bridge link show dev cni0 && \
																						  printf '\n---[IP Tables]--- \n' && \
																						  sudo iptables -vL -t filter && \
																						  sudo iptables -vL -t nat && \
																						  sudo iptables -vL -t mangle && \
																						  sudo iptables -vL -t raw && \
																						  sudo iptables -vL -t security \
																						  " >>network-configuration.txt
echo -e "\n ###------------>>> POD 1 <<<------------###\n" >>network-configuration.txt
kubectl exec -it "$POD_NAME_1" -- bash -c "printf '\n---[IP Addresses]--- \n' && ip a && printf '\n---[IP Routes]--- \n' && ip r" >>network-configuration.txt
echo -e "\n ###------------>>> POD 2 <<<------------###\n" >>network-configuration.txt
kubectl exec -it "$POD_NAME_2" -- bash -c "printf '\n---[IP Addresses]--- \n' && ip a && printf '\n---[IP Routes]--- \n' && ip r" >>network-configuration.txt
echo -e "\n ###------------>>> POD 3 <<<------------###\n" >>network-configuration.txt
kubectl exec -it "$POD_NAME_3" -- bash -c "printf '\n---[IP Addresses]--- \n' && ip a && printf '\n---[IP Routes]--- \n' && ip r" >>network-configuration.txt
