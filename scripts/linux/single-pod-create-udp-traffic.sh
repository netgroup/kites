#!/bin/bash
## Get Hostname, MAC Address and IP for single POD
CNI=$1
N=$2
RUN_TEST_SAME=$3
RUN_TEST_SAMENODE=$4
RUN_TEST_DIFF=$5

echo "diff nodes? $RUN_TEST_DIFF"
POD=$(kubectl get pod -l app=net-test-single-pod -o jsonpath="{.items[0].metadata.name}")
MAC_ADDR_SINGLE_POD=$(kubectl exec -i $POD -- bash -c "vagrant/ext/kites/scripts/linux/single-pod-get-mac-address.sh")
IP_PARSED_SINGLE_POD=$(kubectl exec -i $POD -- bash -c "vagrant/ext/kites/scripts/linux/single-pod-get-ip.sh")
single_pod_vm=$(awk 'NR=='$((N + 2))' { print $3}' podNameAndIP.txt)

echo "Creating UDP Packets for single POD" 
if $RUN_TEST_SAME; then
	bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 100 singlePodToSinglePod single-pod $CNI
	bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" 1000 singlePodToSinglePod single-pod $CNI
fi
bytes=(100 1000)
for byte in "${bytes[@]}"
do
   for (( i=1; i<=$N; i++ ))
   do
   		declare ip1_name="IP_$i"
		declare mac_pod="MAC_ADDR_POD_$i"
		declare name_vm1="VM_NAME_$i"
		echo "nomehost ${!name_vm1} e nome single pod $single_pod_vm ed vero? $RUN_TEST_DIFF"
		if  ( [ "${single_pod_vm//[$' ']/}" = "${!name_vm1//[$' ']/}" ] && $RUN_TEST_SAMENODE ) || ( [ "${single_pod_vm//[$' ']/}" != "${!name_vm1//[$' ']/}" ] && $RUN_TEST_DIFF ); then
			echo "$single_pod_vm = ${!name_vm1}"
			bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"${!mac_pod}\"" "\"$IP_PARSED_SINGLE_POD\"" "\"${!ip1_name}\"" $byte singlePodToPod$i single-pod $CNI
			bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"${!mac_pod}\"" "\"$IP_PARSED_SINGLE_POD\"" "\"${!ip1_name}\"" $byte singlePodToPod$i pod$i $CNI
		fi
	done
done