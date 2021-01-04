#!/bin/bash
## Get Hostname, MAC Address and IP for single POD
CNI=$1
N=$2
RUN_TEST_SAME=$3
RUN_TEST_SAMENODE=$4
RUN_TEST_DIFF=$5
shift 5
bytes=("$@")

echo "diff nodes? $RUN_TEST_DIFF"


echo "Creating UDP Packets for single POD"
if $RUN_TEST_SAME; then
	for byte in "${bytes[@]}"
	do
		bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" $byte singlePodToSinglePod single-pod $CNI
	done
fi

for byte in "${bytes[@]}"
do
   for (( i=1; i<=$N; i++ ))
   do
   		declare ip1_name="IP_$i"
		declare mac_pod="MAC_ADDR_POD_$i"
		declare name_vm1="POD_HOSTNAME_$i"
		echo "nomehost ${!name_vm1} e nome single pod $SINGLE_POD_HOSTNAME ed vero? $RUN_TEST_DIFF"
		if  ( [ "${SINGLE_POD_HOSTNAME//[$' ']/}" = "${!name_vm1//[$' ']/}" ] && $RUN_TEST_SAMENODE ) || ( [ "${SINGLE_POD_HOSTNAME//[$' ']/}" != "${!name_vm1//[$' ']/}" ] && $RUN_TEST_DIFF ); then
			echo "$SINGLE_POD_HOSTNAME = ${!name_vm1}"
			bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"${!mac_pod}\"" "\"$IP_PARSED_SINGLE_POD\"" "\"${!ip1_name}\"" $byte singlePodToPod$i single-pod $CNI
			bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"${!mac_pod}\"" "\"$IP_PARSED_SINGLE_POD\"" "\"${!ip1_name}\"" $byte singlePodToPod$i pod$i $CNI
		fi
	done
done