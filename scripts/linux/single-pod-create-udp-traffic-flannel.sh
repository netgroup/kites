#!/bin/bash
## Get Hostname, MAC Address and IP for single POD
CNI=$1
POD=$(kubectl get pod -l app=net-test-single-pod -o jsonpath="{.items[0].metadata.name}")
MAC_ADDR_SINGLE_POD=$(kubectl exec -it $POD -- bash -c "vagrant/ext/kites/scripts/linux/single-pod-get-mac-address.sh")
IP_PARSED_SINGLE_POD=$(kubectl exec -it $POD -- bash -c "vagrant/ext/kites/scripts/linux/single-pod-get-ip.sh")
echo "Creating UDP Packets for single POD" 

MINION_1=$(awk 'NR==2 { print $3}' podNameAndIP.txt)
MINION_2=$(awk 'NR==3 { print $3}' podNameAndIP.txt)
MINION_3=$(awk 'NR==4 { print $3}' podNameAndIP.txt)
MINION_SINGLE_POD=$(awk 'NR==5 { print $3}' podNameAndIP.txt)
if [ "$MINION_1" = "$MINION_SINGLE_POD" ]; then
	bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 100 singlePodToSinglePod single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 100 singlePodToPod1 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 100 singlePodToPod2 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 100 singlePodToPod3 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 100 singlePodToPod1 pod1 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 100 singlePodToPod2 pod2 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 100 singlePodToPod3 pod3 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 1000 singlePodToSinglePod single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 1000 singlePodToPod1 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 1000 singlePodToPod2 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 1000 singlePodToPod3 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 1000 singlePodToPod1 pod1 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 1000 singlePodToPod2 pod2 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_1\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 1000 singlePodToPod3 pod3 $CNI
elif [ "$MINION_2" = "$MINION_SINGLE_POD" ]
then
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 100 singlePodToSinglePod single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 100 singlePodToPod1 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 100 singlePodToPod2 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 100 singlePodToPod3 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 100 singlePodToPod1 pod1 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 100 singlePodToPod2 pod2 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 100 singlePodToPod3 pod3 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 1000 singlePodToSinglePod single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 1000 singlePodToPod1 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 1000 singlePodToPod2 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 1000 singlePodToPod3 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 1000 singlePodToPod1 pod1 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 1000 singlePodToPod2 pod2 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_2\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 1000 singlePodToPod3 pod3 $CNI
else
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 100 singlePodToSinglePod single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 100 singlePodToPod1 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 100 singlePodToPod2 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 100 singlePodToPod3 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 100 singlePodToPod1 pod1 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 100 singlePodToPod2 pod2 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 100 singlePodToPod3 pod3 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 1000 singlePodToSinglePod single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 1000 singlePodToPod1 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 1000 singlePodToPod2 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 1000 singlePodToPod3 single-pod $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_1\"" 1000 singlePodToPod1 pod1 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_MINION_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_2\"" 1000 singlePodToPod2 pod2 $CNI
    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_POD_3\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_3\"" 1000 singlePodToPod3 pod3 $CNI
fi
