#!/bin/bash
CNI=$1
if [ -d "/vagrant/ext/kites/pod-shared/" ] 
then
    cd /vagrant/ext/kites/pod-shared/
else
    echo "Directory /vagrant/ext/kites/pod-shared/ doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/pod-shared/"
    mkdir -p /vagrant/ext/kites/pod-shared/ && cd /vagrant/ext/kites/pod-shared/ 
fi
echo "Obtaining the names of the DaemonSet..."
POD_1=$(awk 'NR==2 { print $1}' podNameAndIP.txt)
POD_2=$(awk 'NR==3 { print $1}' podNameAndIP.txt)
POD_3=$(awk 'NR==4 { print $1}' podNameAndIP.txt)
echo "Obtaining the IPs of the DaemonSet..."
POD_IP_1=$(awk 'NR==2 { print $2}' podNameAndIP.txt)
POD_IP_2=$(awk 'NR==3 { print $2}' podNameAndIP.txt)
POD_IP_3=$(awk 'NR==4 { print $2}' podNameAndIP.txt)
IP_1=$(sed -e "s/\./, /g" <<< $POD_IP_1)
IP_2=$(sed -e "s/\./, /g" <<< $POD_IP_2)
IP_3=$(sed -e "s/\./, /g" <<< $POD_IP_3)
#echo "POD 1 NAME = ${POD_1} IP = ${POD_IP_1}" &&  echo "POD 2 NAME = ${POD_2} IP = ${POD_IP_2}" && echo "POD 3 NAME = ${POD_3} IP = ${POD_IP_3}"
#echo ${IP_1} && echo ${IP_2} && echo ${IP_3}
echo "Obtaining MAC Addresses of the DaemonSet..."
MAC_ADDR_POD_1=$(kubectl exec -it "$POD_1" -- bash -c "vagrant/ext/kites/scripts/linux/get-mac-address-pod.sh")
MAC_ADDR_POD_2=$(kubectl exec -it "$POD_2" -- bash -c "vagrant/ext/kites/scripts/linux/get-mac-address-pod.sh")
MAC_ADDR_POD_3=$(kubectl exec -it "$POD_3" -- bash -c "vagrant/ext/kites/scripts/linux/get-mac-address-pod.sh")
if [ "$CNI" == "flannel" ]; then
   echo "Obtaining MAC Addresses of the Nodes for $CNI..."
   sudo apt-get install -y sshpass
   MINION_1=$(awk 'NR==2 { print $3}' podNameAndIP.txt)
   MINION_2=$(awk 'NR==3 { print $3}' podNameAndIP.txt)
   MINION_3=$(awk 'NR==4 { print $3}' podNameAndIP.txt)
   MAC_ADDR_MINION_1=$(sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@$MINION_1 "/vagrant/ext/kites/scripts/linux/get-mac-address-cni-node.sh")
   MAC_ADDR_MINION_2=$(sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@$MINION_2 "/vagrant/ext/kites/scripts/linux/get-mac-address-cni-node.sh")
   MAC_ADDR_MINION_3=$(sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@$MINION_3 "/vagrant/ext/kites/scripts/linux/get-mac-address-cni-node.sh")
   echo "Creating UDP Packet for DaemonSet..."
   export IP_1 IP_2 IP_3 MAC_ADDR_POD_1 MAC_ADDR_POD_2 MAC_ADDR_POD_3 MAC_ADDR_MINION_1 MAC_ADDR_MINION_2 MAC_ADDR_MINION_3
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_1\"" "\"$IP_1\"" 100 samePod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_1\"" "\"$IP_2\"" 100 pod1ToPod2 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_1\"" "\"$IP_3\"" 100 pod1ToPod3 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_2\"" "\"$IP_1\"" 100 pod2ToPod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_3\"" "\"$IP_1\"" 100 pod3ToPod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_2\"" "\"$IP_2\"" 100 samePod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_2\"" "\"$IP_1\"" 100 pod2ToPod1 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_2\"" "\"$IP_3\"" 100 pod2ToPod3 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_3\"" "\"$IP_1\"" 100 pod3ToPod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_1\"" "\"$IP_2\"" 100 pod1ToPod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_3\"" "\"$IP_3\"" 100 samePod3 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_3\"" "\"$IP_1\"" 100 pod3ToPod1 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_3\"" "\"$IP_2\"" 100 pod3ToPod2 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_1\"" "\"$IP_3\"" 100 pod1ToPod3 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_2\"" "\"$IP_3\"" 100 pod2ToPod3 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_1\"" "\"$IP_1\"" 1000 samePod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_1\"" "\"$IP_2\"" 1000 pod1ToPod2 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_1\"" "\"$IP_3\"" 1000 pod1ToPod3 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_2\"" "\"$IP_1\"" 1000 pod2ToPod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_3\"" "\"$IP_1\"" 1000 pod3ToPod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_2\"" "\"$IP_2\"" 1000 samePod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_2\"" "\"$IP_1\"" 1000 pod2ToPod1 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_2\"" "\"$IP_3\"" 1000 pod2ToPod3 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_3\"" "\"$IP_1\"" 1000 pod3ToPod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_1\"" "\"$IP_2\"" 1000 pod1ToPod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_3\"" "\"$IP_3\"" 1000 samePod3 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_3\"" "\"$IP_1\"" 1000 pod3ToPod1 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_3\"" "\"$IP_2\"" 1000 pod3ToPod2 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_1\"" "\"$IP_3\"" 1000 pod1ToPod3 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_2\"" "\"$IP_3\"" 1000 pod2ToPod3 pod3 $CNI
   echo "Creating UDP Packets for Single Pod..."
   /vagrant/ext/kites/scripts/linux/single-pod-create-udp-traffic-flannel.sh $CNI
else
   echo "Creating UDP Packet for DaemonSet..."
   export IP_1 IP_2 IP_3 MAC_ADDR_POD_1 MAC_ADDR_POD_2 MAC_ADDR_POD_3
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_1\"" "\"$IP_1\"" 100 samePod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_1\"" "\"$IP_2\"" 100 pod1ToPod2 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_1\"" "\"$IP_3\"" 100 pod1ToPod3 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_2\"" "\"$IP_1\"" 100 pod2ToPod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_3\"" "\"$IP_1\"" 100 pod3ToPod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_2\"" "\"$IP_2\"" 100 samePod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_2\"" "\"$IP_1\"" 100 pod2ToPod1 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_2\"" "\"$IP_3\"" 100 pod2ToPod3 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_3\"" "\"$IP_1\"" 100 pod3ToPod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_1\"" "\"$IP_2\"" 100 pod1ToPod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_3\"" "\"$IP_3\"" 100 samePod3 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_3\"" "\"$IP_1\"" 100 pod3ToPod1 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_3\"" "\"$IP_2\"" 100 pod3ToPod2 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_1\"" "\"$IP_3\"" 100 pod1ToPod3 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_2\"" "\"$IP_3\"" 100 pod2ToPod3 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_1\"" "\"$IP_1\"" 1000 samePod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_1\"" "\"$IP_2\"" 1000 pod1ToPod2 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_1\"" "\"$IP_3\"" 1000 pod1ToPod3 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_2\"" "\"$IP_1\"" 1000 pod2ToPod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_3\"" "\"$IP_1\"" 1000 pod3ToPod1 pod1 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_2\"" "\"$IP_2\"" 1000 samePod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_2\"" "\"$IP_1\"" 1000 pod2ToPod1 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_2\"" "\"$IP_3\"" 1000 pod2ToPod3 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_3\"" "\"$IP_1\"" 1000 pod3ToPod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_1\"" "\"$IP_2\"" 1000 pod1ToPod2 pod2 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_3\"" "\"$IP_3\"" 1000 samePod3 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_3\"" "\"$IP_1\"" 1000 pod3ToPod1 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_3\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_3\"" "\"$IP_2\"" 1000 pod3ToPod2 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_1\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_1\"" "\"$IP_3\"" 1000 pod1ToPod3 pod3 $CNI
   /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"$MAC_ADDR_POD_2\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_2\"" "\"$IP_3\"" 1000 pod2ToPod3 pod3 $CNI
   echo "Creating Single POD and UDP Packet for this..."
   /vagrant/ext/kites/scripts/linux/single-pod-create-udp-traffic.sh $CNI
fi
