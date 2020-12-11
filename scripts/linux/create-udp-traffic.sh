#!/bin/bash
CNI=$1
N=$2
RUN_TEST_SAME=$3
RUN_TEST_SAMENODE=$4
RUN_TEST_DIFF=$5
echo "same $RUN_TEST_SAME same node $RUN_TEST_SAMENODE diff node $RUN_TEST_DIFF"

echo "$(kubectl get pods -o wide)"

if [ -d "/vagrant/ext/kites/pod-shared/" ] 
then
    cd /vagrant/ext/kites/pod-shared/
else
    echo "Directory /vagrant/ext/kites/pod-shared/ doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/pod-shared/"
    mkdir -p /vagrant/ext/kites/pod-shared/ && cd /vagrant/ext/kites/pod-shared/ 
fi


echo "Obtaining the names of the DaemonSet..."
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
   declare n_plus=$((minion_n + 1))
   nome_pod=$(awk 'NR=='$n_plus' { print $1}' podNameAndIP.txt)
   declare -x "POD_$minion_n"=$nome_pod
done

echo "Obtaining the IPs of the DaemonSet..."
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
   declare n_plus=$((minion_n + 1))
   ip_pod=$(awk 'NR=='$n_plus' { print $2}' podNameAndIP.txt)
   declare -x "POD_IP_$minion_n= $ip_pod"

   declare ip_name=POD_IP_$minion_n
   ip_parsed_pods=$(sed -e "s/\./, /g" <<< ${!ip_name})
   declare -x "IP_$minion_n= $ip_parsed_pods"
done

echo "Obtaining MAC Addresses of the DaemonSet..."
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
   declare pod_names=POD_$minion_n 
   mac_pod=$(kubectl exec -i "${!pod_names}" -- bash -c "vagrant/ext/kites/scripts/linux/get-mac-address-pod.sh")
   declare "MAC_ADDR_POD_$minion_n=$mac_pod"
done

echo "Obtaining the names of the VMs..."
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
   declare n_plus=$((minion_n + 1))
   name_vm=$(awk 'NR=='$n_plus' { print $3}' podNameAndIP.txt)
   declare -x "VM_NAME_$minion_n= $name_vm"
done


if [ "$CNI" == "flannel" ]; then
   echo "TO BE CHECKED"
   echo "Obtaining MAC Addresses of the Nodes for $CNI..."
   sudo apt install -y sshpass
   for (( minion_n=1; minion_n<=$N; minion_n++ ))
   do
      declare minion="VM_NAME_$minion_n"
      echo ${!minion}
      min_mac=$(sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@${!minion//[$' ']/}.k8s-play.local "/vagrant/ext/kites/scripts/linux/get-mac-address-cni-node.sh")
      declare -x "MAC_ADDR_MINION_$minion_n= $min_mac"
   done
   echo "Creating UDP Packet for DaemonSet..."
   for (( minion_n=1; minion_n<=$N; minion_n++ ))
   do
      export IP_$minion_n MAC_ADDR_POD_$minion_n MAC_ADDR_MINION_$minion_n
   done
   bytes=(100 1000)
   for byte in "${bytes[@]}"
   do
      echo "$byte bytes"
      for (( i=1; i<=$N; i++ ))
      do
         for (( j=1; j<=$N; j++ ))
         do
            declare ip1_name="IP_$i"
            declare ip2_name="IP_$j"
            declare mac1_pod="MAC_ADDR_POD_$i"
            declare mac2_pod="MAC_ADDR_POD_$j"
            declare mac1_minion="MAC_ADDR_MINON_$i"
            declare mac2_minion="MAC_ADDR_MINON_$j"
            if [ "$i" -eq "$j" ]; then
               /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"${!mac1_pod}\"" "\"${!mac1_pod}\"" "\"${!ip1_name}\"" "\"${!ip2_name}\"" $byte samePod$i pod$i $CNI
            else
               /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"${!mac1_pod}\"" "\"${!mac1_minion}\"" "\"${!ip1_name}\"" "\"${!ip2_name}\"" $byte pod${i}ToPod${j} pod$i $CNI
               /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"${!mac2_pod}\"" "\"${!mac2_minion}\"" "\"${!ip2_name}\"" "\"${!ip1_name}\"" $byte pod${j}ToPod${i} pod$i $CNI
            fi
         done
      done
   done
   echo "Creating UDP Packets for Single Pod..."
   /vagrant/ext/kites/scripts/linux/single-pod-create-udp-traffic-flannel.sh $CNI $N
else
   echo "Creating UDP Packet for DaemonSet..."
   for (( minion_n=1; minion_n<=$N; minion_n++ ))
   do
      export IP_$minion_n MAC_ADDR_POD_$minion_n VM_NAME_$minion_n
   done
   bytes=(100 1000)
   for byte in "${bytes[@]}"
   do
      echo "$byte bytes"
      for (( i=1; i<=$N; i++ ))
      do
         for (( j=1; j<=$N; j++ ))
         do
            declare ip1_name="IP_$i"
            declare ip2_name="IP_$j"
            declare mac1_pod="MAC_ADDR_POD_$i"
            declare mac2_pod="MAC_ADDR_POD_$j"
            declare name_vm1="VM_NAME_$i"
            declare name_vm2="VM_NAME_$j"
            if [ "$i" -eq "$j" ] && $RUN_TEST_SAME; then
               echo "Same pods"
               /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"${!mac1_pod}\"" "\"${!mac1_pod}\"" "\"${!ip1_name}\"" "\"${!ip2_name}\"" $byte samePod$i pod$i $CNI
            elif [ "${!name_vm1}" != "${!name_vm2}" ] && $RUN_TEST_DIFF; then
               echo "diff nodes"
               /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"${!mac1_pod}\"" "\"${!mac2_pod}\"" "\"${!ip1_name}\"" "\"${!ip2_name}\"" $byte pod${i}ToPod${j} pod$i $CNI
               /vagrant/ext/kites/scripts/linux/create-udp-packets.sh "\"${!mac2_pod}\"" "\"${!mac1_pod}\"" "\"${!ip2_name}\"" "\"${!ip1_name}\"" $byte pod${j}ToPod${i} pod$i $CNI
            fi
         done
      done
   done
   if $RUN_TEST_SAMENODE; then
      echo "Creating Single POD and UDP Packet for this..."
      /vagrant/ext/kites/scripts/linux/single-pod-create-udp-traffic.sh $CNI $N $RUN_TEST_SAME $RUN_TEST_SAMENODE $RUN_TEST_DIFF
   fi
fi
