#!/bin/bash
## Get Hostname, MAC Address and IP for single POD
CNI=$1
POD=$(kubectl get pod -l app=net-test-single-pod -o jsonpath="{.items[0].metadata.name}")
MAC_ADDR_SINGLE_POD=$(kubectl exec -it "$POD" -- bash -c "vagrant/ext/kites/scripts/linux/single-pod-get-mac-address.sh")
IP_PARSED_SINGLE_POD=$(kubectl exec -it "$POD" -- bash -c "vagrant/ext/kites/scripts/linux/single-pod-get-ip.sh")
echo "Creating UDP Packets for single POD" 
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 100 singlePodToSinglePod single-pod $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 100 singlePodToPod1 single-pod $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 100 singlePodToPod1 pod1 $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 100 singlePodToPod2 single-pod $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 100 singlePodToPod2 pod2 $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 100 singlePodToPod3 single-pod $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 100 singlePodToPod3 pod3 $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 1000 singlePodToSinglePod single-pod $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 1000 singlePodToPod1 single-pod $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 1000 singlePodToPod2 single-pod $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 1000 singlePodToPod3 single-pod $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 1000 singlePodToPod1 pod1 $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 1000 singlePodToPod2 pod2 $CNI
bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 1000 singlePodToPod3 pod3 $CNI
