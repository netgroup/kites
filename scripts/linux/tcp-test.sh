#!/bin/sh
BASE_FOLDER=/vagrant/ext/kites/pod-shared
cd $BASE_FOLDER
POD_NAME_1=$(awk 'NR==2 { print $1}' podNameAndIP.txt)
POD_NAME_2=$(awk 'NR==3 { print $1}' podNameAndIP.txt)
POD_NAME_3=$(awk 'NR==4 { print $1}' podNameAndIP.txt)
POD_IP_1=$(awk 'NR==2 { print $2}' podNameAndIP.txt)
POD_IP_2=$(awk 'NR==3 { print $2}' podNameAndIP.txt)
POD_IP_3=$(awk 'NR==4 { print $2}' podNameAndIP.txt)
POD_HOSTNAME_1=$(awk 'NR==2 { print $3}' podNameAndIP.txt)
POD_HOSTNAME_2=$(awk 'NR==3 { print $3}' podNameAndIP.txt)
POD_HOSTNAME_3=$(awk 'NR==4 { print $3}' podNameAndIP.txt)
SINGLE_POD_NAME=$(awk 'NR==5 { print $1}' podNameAndIP.txt)
SINGLE_POD_IP=$(awk 'NR==5 { print $2}' podNameAndIP.txt)
SINGLE_POD_HOSTNAME=$(awk 'NR==5 { print $3}' podNameAndIP.txt)
echo -e "TCP TEST\n" > TCP_IPERF_OUTPUT.txt
echo -e "POD 1 to other PODS...\n"
echo -e "----------------------------------------------\n\n"
kubectl exec -it $POD_NAME_1 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_1\" \"$POD_IP_1\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_1\" \"$POD_NAME_1\" \"$POD_NAME_1\""
kubectl exec -it $POD_NAME_1 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_1\" \"$POD_IP_2\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_2\" \"$POD_NAME_1\" \"$POD_NAME_2\""
kubectl exec -it $POD_NAME_1 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_1\" \"$POD_IP_3\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_3\" \"$POD_NAME_1\" \"$POD_NAME_3\""
kubectl exec -it $POD_NAME_1 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_1\" \"$SINGLE_POD_IP\" \"$POD_HOSTNAME_1\" \"$SINGLE_POD_HOSTNAME\" \"$POD_NAME_1\" \"$SINGLE_POD_NAME\""
echo -e "\nPOD 2 to other PODS...\n"
echo -e "----------------------------------------------\n\n"
kubectl exec -it $POD_NAME_2 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_2\" \"$POD_IP_1\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_1\" \"$POD_NAME_1\" \"$POD_NAME_1\""
kubectl exec -it $POD_NAME_2 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_2\" \"$POD_IP_2\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_2\" \"$POD_NAME_2\" \"$POD_NAME_2\""
kubectl exec -it $POD_NAME_2 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_2\" \"$POD_IP_3\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_3\" \"$POD_NAME_2\" \"$POD_NAME_3\""
kubectl exec -it $POD_NAME_2 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_2\" \"$SINGLE_POD_IP\" \"$POD_HOSTNAME_2\" \"$SINGLE_POD_HOSTNAME\" \"$POD_NAME_2\" \"$SINGLE_POD_NAME\""
echo -e "\nPOD 3 to other PODS...\n"
echo -e "----------------------------------------------\n\n"
kubectl exec -it $POD_NAME_3 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_3\" \"$POD_IP_1\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_1\" \"$POD_NAME_3\" \"$POD_NAME_1\"" 
kubectl exec -it $POD_NAME_3 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_3\" \"$POD_IP_2\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_2\" \"$POD_NAME_3\" \"$POD_NAME_2\"" 
kubectl exec -it $POD_NAME_3 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_3\" \"$POD_IP_3\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_3\" \"$POD_NAME_3\" \"$POD_NAME_3\"" 
kubectl exec -it $POD_NAME_3 -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"$POD_IP_3\" \"$SINGLE_POD_IP\" \"$POD_HOSTNAME_3\" \"$SINGLE_POD_HOSTNAME\" \"$POD_NAME_3\" \"$SINGLE_POD_NAME\""
