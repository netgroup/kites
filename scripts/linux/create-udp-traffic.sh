#!/bin/bash
CNI=$1
N=$2
RUN_TEST_SAME=$3
RUN_TEST_SAMENODE=$4
RUN_TEST_DIFF=$5
shift 5
bytes=("$@")


if [ "$CNI" == "flannel" ]; then
   echo "Obtaining MAC Addresses of the Nodes for $CNI..."

   for (( minion_n=1; minion_n<=$N; minion_n++ ))
   do
      declare minion="POD_HOSTNAME_$minion_n"
      echo ${!minion}
      min_mac=$(sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@${!minion//[$' ']/}.k8s-play.local "/vagrant/ext/kites/scripts/linux/get-mac-address-cni-node.sh")
      declare -x "MAC_ADDR_MINION_$minion_n=$min_mac"
   done
   echo "Creating UDP Packet for DaemonSet..."
   for (( minion_n=1; minion_n<=$N; minion_n++ ))
   do
      export IP_$minion_n MAC_ADDR_POD_$minion_n MAC_ADDR_MINION_$minion_n
   done
   for byte in "${bytes[@]}"
   do
      echo "Creating UDP packets with size: $byte bytes"
      for (( i=1; i<=$N; i++ ))
      do
         for (( j=1; j<=$N; j++ ))
         do
            declare ip1_name="IP_$i"
            declare ip2_name="IP_$j"
            declare mac1_pod="MAC_ADDR_POD_$i"
            declare mac2_pod="MAC_ADDR_POD_$j"
            declare mac1_minion="MAC_ADDR_MINION_$i"
            declare mac2_minion="MAC_ADDR_MINION_$j"
            if [ "$i" -eq "$j" ]; then
               ${KITES_HOME}/scripts/linux/create-udp-packets.sh "\"${!mac1_pod}\"" "\"${!mac1_pod}\"" "\"${!ip1_name}\"" "\"${!ip2_name}\"" $byte samePod$i pod$i $CNI
            else
               ${KITES_HOME}/scripts/linux/create-udp-packets.sh "\"${!mac1_pod}\"" "\"${!mac1_minion}\"" "\"${!ip1_name}\"" "\"${!ip2_name}\"" $byte pod${i}ToPod${j} pod$i $CNI
               ${KITES_HOME}/scripts/linux/create-udp-packets.sh "\"${!mac2_pod}\"" "\"${!mac2_minion}\"" "\"${!ip2_name}\"" "\"${!ip1_name}\"" $byte pod${j}ToPod${i} pod$i $CNI
            fi
         done
      done
   done
   echo "Creating UDP Packets for Single Pod..."
   ${KITES_HOME}s/scripts/linux/single-pod-create-udp-traffic-flannel.sh $CNI $N "${bytes[@]}"
else
   echo "Creating UDP Packet for DaemonSet..."
   
   for byte in "${bytes[@]}"
   do
      echo "Creating UDP packets with size: $byte bytes"
      for (( i=1; i<=$N; i++ ))
      do
         for (( j=1; j<=$N; j++ ))
         do
            declare ip1_name="IP_$i"
            declare ip2_name="IP_$j"
            declare mac1_pod="MAC_ADDR_POD_$i"
            declare mac2_pod="MAC_ADDR_POD_$j"
            declare name_vm1="POD_HOSTNAME_$i"
            declare name_vm2="POD_HOSTNAME_$j"
            if [ "$i" -eq "$j" ] && $RUN_TEST_SAME; then
               echo "Same pods"
               ${KITES_HOME}/scripts/linux/create-udp-packets.sh "\"${!mac1_pod}\"" "\"${!mac1_pod}\"" "\"${!ip1_name}\"" "\"${!ip2_name}\"" $byte samePod$i pod$i $CNI
            elif [ "${!name_vm1}" != "${!name_vm2}" ] && $RUN_TEST_DIFF; then
               echo "diff nodes"
               ${KITES_HOME}/scripts/linux/create-udp-packets.sh "\"${!mac1_pod}\"" "\"${!mac2_pod}\"" "\"${!ip1_name}\"" "\"${!ip2_name}\"" $byte pod${i}ToPod${j} pod$i $CNI
               ${KITES_HOME}/scripts/linux/create-udp-packets.sh "\"${!mac2_pod}\"" "\"${!mac1_pod}\"" "\"${!ip2_name}\"" "\"${!ip1_name}\"" $byte pod${j}ToPod${i} pod$i $CNI
            fi
         done
      done
   done
   if $RUN_TEST_SAMENODE; then
      echo "Creating Single POD and UDP Packet for this..."
      ${KITES_HOME}/scripts/linux/single-pod-create-udp-traffic.sh "$CNI" "$N" "$RUN_TEST_SAME" "$RUN_TEST_SAMENODE" "$RUN_TEST_DIFF" "${bytes[@]}"
   fi
fi
