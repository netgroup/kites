#!/bin/bash
## Get Hostname, MAC Address and IP for single POD
CNI=$1
N=$2
shift 2
bytes=("$@")


echo "Creating UDP Packets for single POD" 
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
   declare n_plus=$((minion_n + 1))
   host_pod=$(awk 'NR=='$n_plus' { print $3}' podNameAndIP.txt)
   declare -x "MINION_$minion_n= $host_pod"
done
MINION_SINGLE_POD=$(awk 'NR=='$((N + 2))' { print $3}' podNameAndIP.txt)

for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
    declare hostname="MINION_$minion_n"
    if [ "${!hostname//[$' ']/}" = "$MINION_SINGLE_POD" ]; then
        # bytes=(100 1000)
        for byte in "${bytes[@]}"
        do
            echo "Creating UDP packets with size: $byte bytes"
            bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"$MAC_ADDR_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" "\"$IP_PARSED_SINGLE_POD\"" $byte singlePodToSinglePod single-pod $CNI
            for (( j=1; j<=$N; j++ ))
            do
                declare mac_addr_pod="MAC_ADDR_POD_$minion_n"
                declare mac_addr_minion="MAC_ADDR_MINION_$minion_n"
                declare ip_pod="IP_$j"
                if [ $minion_n -eq $j ]; then
                    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"${!mac_addr_pod}\"" "\"$IP_PARSED_SINGLE_POD\"" "\"${!ip_pod}\"" $byte singlePodToPod$j single-pod $CNI
                    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"${!mac_addr_pod}\"" "\"$IP_PARSED_SINGLE_POD\"" "\"${!ip_pod}\"" $byte singlePodToPod$j pod$j $CNI
                else
                    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"${!mac_addr_minion}\"" "\"$IP_PARSED_SINGLE_POD\"" "\"${!ip_pod}\"" $byte singlePodToPod$j single-pod $CNI
                    bash /vagrant/ext/kites/scripts/linux/single-pod-create-udp-packets.sh "\"$MAC_ADDR_SINGLE_POD\"" "\"${!mac_addr_minion}\"" "\"$IP_PARSED_SINGLE_POD\"" "\"${!ip_pod}\"" $byte singlePodToPod$j pod$j $CNI
                fi
            done
        done
    fi
done
