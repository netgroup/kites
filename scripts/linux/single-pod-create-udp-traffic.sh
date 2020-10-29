#!/bin/bash
## Get Hostname, MAC Address and IP for single POD
CNI=$1
N=$2
POD=$(kubectl get pod -l app=net-test-single-pod -o jsonpath="{.items[0].metadata.name}")
echo "get pod:"
echo "$(kubectl get pods -o wide | grep $POD)"
MAC_ADDR_SINGLE_POD=$(kubectl exec -i $POD -- bash -c "vagrant/ext/kites/scripts/linux/single-pod-get-mac-address.sh")
IP_PARSED_SINGLE_POD=$(kubectl exec -i $POD -- bash -c "vagrant/ext/kites/scripts/linux/single-pod-get-ip.sh")

echo "Creating UDP Packets for single POD" 
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 100 singlePodToSinglePod single-pod $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 1000 singlePodToSinglePod single-pod $CNI
bytes=(100 1000)
for byte in "${bytes[@]}"
do
   echo "$byte bytes"
   for (( i=1; i<=$N; i++ ))
   do
   		declare ip1_name="IP_$i"
		declare mac_pod="MAC_ADDR_POD_$i"
   		bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"${!mac_pod}\"" "\"$IP_PARSED_SINGLE_POD\"" "\"${!ip1_name}\"" $byte singlePodToPod$i single-pod $CNI
   		bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"${!mac_pod}\"" "\"$IP_PARSED_SINGLE_POD\"" "\"${!ip1_name}\"" $byte singlePodToPod$i pod$i $CNI
   	done
done