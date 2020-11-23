#!/bin/bash
#TODO INSERIRE INTERFACCIA ETH1
#SE VIRTUALBOX INVECE ENP0S8
HOSTNAME=$(hostname)
N=$2
echo $HOSTNAME
VAGRANT_PROVIDER=$(awk 'NR==3 { print $2}' /vagrant/env.yaml)
if [ "$VAGRANT_PROVIDER" == "libvirt" ]; then
   /sbin/ip a | grep "eth1" | grep "inet" | awk 'NR==1 { print $2}' > example.txt
else
   /sbin/ip a | grep "enp0s8" | grep "inet" | awk 'NR==1 { print $2}' > example.txt
fi
IP_HOSTNAME=$(sed -e 's/.\{3\}$//' example.txt)
echo $IP_HOSTNAME
#Install package if not installed
sudo apt install -y iperf3 
#Start Iperf3 TCP Test
BASE_FOLDER=/vagrant/ext/kites/pod-shared
cd $BASE_FOLDER

for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
   declare n_plus=$((minion_n + 1))
   name_pod=$(awk 'NR=='$n_plus' { print $1}' podNameAndIP.txt)
   ip_pod=$(awk 'NR=='$n_plus' { print $2}' podNameAndIP.txt)
   host_pod=$(awk 'NR=='$n_plus' { print $3}' podNameAndIP.txt)
   declare -x "POD_NAME_$minion_n= $name_pod"
   declare -x "POD_IP_$minion_n= $ip_pod"
   declare -x "POD_HOSTNAME_$minion_n= $host_pod"
done
declare n_plus=$((N + 2))
SINGLE_POD_NAME=$(awk 'NR=='$n_plus' { print $1}' podNameAndIP.txt)
SINGLE_POD_IP=$(awk 'NR=='$n_plus' { print $2}' podNameAndIP.txt)
SINGLE_POD_HOSTNAME=$(awk 'NR=='$n_plus' { print $3}' podNameAndIP.txt)

ID_EXP=$1
echo -e "$HOSTNAME to other PODS...\n"
echo -e "----------------------------------------------\n\n"
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
   declare name1_pod="POD_NAME_$minion_n"
   declare ip1_pod="POD_IP_$minion_n"
   echo "$ip1_pod = ${!ip1_pod}"
   declare host1_pod="POD_HOSTNAME_$minion_n"
   /vagrant/ext/kites/scripts/linux/iperf-test-node.sh \"$IP_HOSTNAME\" ${!ip1_pod} \"$HOSTNAME\" ${!host1_pod} "NO_POD" ${!name1_pod} $ID_EXP
done
/vagrant/ext/kites/scripts/linux/iperf-test-node.sh \"$IP_HOSTNAME\" \"$SINGLE_POD_IP\" \"$HOSTNAME\" \"$SINGLE_POD_HOSTNAME\" "NO_POD" \"$SINGLE_POD_NAME\" $ID_EXP
exit