#!/bin/bash
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
FOLDER_POD_1=pod1
FOLDER_POD_2=pod2
FOLDER_POD_3=pod3
FOLDER_SINGLE_POD=single-pod
INTER_EXPERIMENT_SLEEP=3
PPS=$1
BYTE=$2
ID_EXP=$3
#echo -e "NETSNIFF TEST - ${BYTE}byte - ${PPS}pps\n" > NETSNIFF-${BYTE}byte-${PPS}pps.txt
#echo -e "TRAFGEN TEST - ${BYTE}byte - ${PPS}pps\n" > TRAFGEN-${BYTE}byte-${PPS}pps.txt

echo "Copy Pod-Shared on Root of the PODS"

kubectl exec -i $POD_NAME_1 -- bash -c "/vagrant/ext/kites/scripts/linux/cp-pod-shared-to-root.sh"
kubectl exec -i $POD_NAME_2 -- bash -c "/vagrant/ext/kites/scripts/linux/cp-pod-shared-to-root.sh"
kubectl exec -i $POD_NAME_3 -- bash -c "/vagrant/ext/kites/scripts/linux/cp-pod-shared-to-root.sh"
kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/cp-pod-shared-to-root.sh"

cd $BASE_FOLDER/$FOLDER_POD_1


echo -e "\n..................POD 1 TEST..................\n"
echo -e "----------------------------------------------\n\n"

kubectl exec -i $POD_NAME_1 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh samePod1-${BYTE}byte.pcap \"$POD_IP_1\" \"$POD_IP_1\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_1\" \"$POD_NAME_1\" \"$POD_NAME_1\" $FOLDER_POD_1 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $POD_NAME_1 -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh samePod1-${BYTE}byte.cfg \"$POD_IP_1\" \"$POD_IP_1\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_1\" \"$POD_NAME_1\" \"$POD_NAME_1\" $FOLDER_POD_1 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP

kubectl exec -i $POD_NAME_1 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh pod2ToPod1-${BYTE}byte.pcap \"$POD_IP_2\" \"$POD_IP_1\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_1\" \"$POD_NAME_2\" \"$POD_NAME_1\" $FOLDER_POD_1 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $POD_NAME_2 -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh pod2ToPod1-${BYTE}byte.cfg \"$POD_IP_2\" \"$POD_IP_1\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_1\" \"$POD_NAME_2\" \"$POD_NAME_1\" $FOLDER_POD_2 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP

kubectl exec -i $POD_NAME_1 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh pod3ToPod1-${BYTE}byte.pcap \"$POD_IP_3\" \"$POD_IP_1\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_1\" \"$POD_NAME_3\" \"$POD_NAME_1\" $FOLDER_POD_1 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $POD_NAME_3 -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh pod3ToPod1-${BYTE}byte.cfg \"$POD_IP_3\" \"$POD_IP_1\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_1\" \"$POD_NAME_3\" \"$POD_NAME_1\" $FOLDER_POD_3 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP

cd $BASE_FOLDER/$FOLDER_POD_2

echo -e "\n..................POD 2 TEST..................\n"
echo -e "----------------------------------------------\n\n"

kubectl exec -i $POD_NAME_2 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh samePod2-${BYTE}byte.pcap \"$POD_IP_2\" \"$POD_IP_2\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_2\" \"$POD_NAME_2\" \"$POD_NAME_2\" $FOLDER_POD_2 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $POD_NAME_2 -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh samePod2-${BYTE}byte.cfg \"$POD_IP_2\" \"$POD_IP_2\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_2\" \"$POD_NAME_2\" \"$POD_NAME_2\" $FOLDER_POD_2 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -i $POD_NAME_2 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh pod1ToPod2-${BYTE}byte.pcap \"$POD_IP_1\" \"$POD_IP_2\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_2\" \"$POD_NAME_1\" \"$POD_NAME_2\" $FOLDER_POD_2 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $POD_NAME_1 -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh pod1ToPod2-${BYTE}byte.cfg \"$POD_IP_1\" \"$POD_IP_2\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_2\" \"$POD_NAME_1\" \"$POD_NAME_2\" $FOLDER_POD_1 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -i $POD_NAME_2 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh pod3ToPod2-${BYTE}byte.pcap \"$POD_IP_3\" \"$POD_IP_2\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_2\" \"$POD_NAME_3\" \"$POD_NAME_2\" $FOLDER_POD_2 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $POD_NAME_3 -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh pod3ToPod2-${BYTE}byte.cfg \"$POD_IP_3\" \"$POD_IP_2\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_2\" \"$POD_NAME_3\" \"$POD_NAME_2\" $FOLDER_POD_3 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP

cd $BASE_FOLDER/$FOLDER_POD_3

echo -e "\n..................POD 3 TEST..................\n"
echo -e "----------------------------------------------\n\n"

kubectl exec -i $POD_NAME_3 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh samePod3-${BYTE}byte.pcap \"$POD_IP_3\" \"$POD_IP_3\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_3\" \"$POD_NAME_3\" \"$POD_NAME_3\" $FOLDER_POD_3 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $POD_NAME_3 -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh samePod3-${BYTE}byte.cfg \"$POD_IP_3\" \"$POD_IP_3\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_3\" \"$POD_NAME_3\" \"$POD_NAME_3\" $FOLDER_POD_3 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -i $POD_NAME_3 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh pod2ToPod3-${BYTE}byte.pcap \"$POD_IP_2\" \"$POD_IP_3\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_3\" \"$POD_NAME_2\" \"$POD_NAME_3\" $FOLDER_POD_3 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $POD_NAME_2 -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh pod2ToPod3-${BYTE}byte.cfg \"$POD_IP_2\" \"$POD_IP_3\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_3\" \"$POD_NAME_2\" \"$POD_NAME_3\" $FOLDER_POD_2 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -i $POD_NAME_3 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh pod1ToPod3-${BYTE}byte.pcap \"$POD_IP_1\" \"$POD_IP_3\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_3\" \"$POD_NAME_1\" \"$POD_NAME_3\" $FOLDER_POD_3 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $POD_NAME_1 -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh pod1ToPod3-${BYTE}byte.cfg \"$POD_IP_1\" \"$POD_IP_3\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_3\" \"$POD_NAME_1\" \"$POD_NAME_3\" $FOLDER_POD_1 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP

cd $BASE_FOLDER/$FOLDER_SINGLE_POD

echo -e "\n..................SINGLE POD TEST..................\n"
echo -e "----------------------------------------------\n\n"

kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh singlePodToSinglePod-${BYTE}byte.pcap \"$SINGLE_POD_IP\" \"$SINGLE_POD_IP\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_NAME\" \"$SINGLE_POD_NAME\" $FOLDER_SINGLE_POD $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh singlePodToSinglePod-${BYTE}byte.cfg \"$SINGLE_POD_IP\" \"$SINGLE_POD_IP\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_NAME\" \"$SINGLE_POD_NAME\" $FOLDER_SINGLE_POD $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -i $POD_NAME_1 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh singlePodToPod1-${BYTE}byte.pcap \"$SINGLE_POD_IP\" \"$POD_IP_1\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_1\" \"$SINGLE_POD_NAME\" \"$POD_NAME_1\" $FOLDER_POD_1 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh singlePodToPod1-${BYTE}byte.cfg \"$SINGLE_POD_IP\" \"$POD_IP_1\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_1\" \"$SINGLE_POD_NAME\" \"$POD_NAME_1\" $FOLDER_SINGLE_POD $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -i $POD_NAME_2 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh singlePodToPod2-${BYTE}byte.pcap \"$SINGLE_POD_IP\" \"$POD_IP_2\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_2\" \"$SINGLE_POD_NAME\" \"$POD_NAME_2\" $FOLDER_POD_2 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh singlePodToPod2-${BYTE}byte.cfg \"$SINGLE_POD_IP\" \"$POD_IP_2\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_2\" \"$SINGLE_POD_NAME\" \"$POD_NAME_2\" $FOLDER_SINGLE_POD $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -i $POD_NAME_3 -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh singlePodToPod3-${BYTE}byte.pcap \"$SINGLE_POD_IP\" \"$POD_IP_3\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_3\" \"$SINGLE_POD_NAME\" \"$POD_NAME_3\" $FOLDER_POD_3 $BYTE $PPS $ID_EXP" &
sleep 2 &&
    kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh singlePodToPod3-${BYTE}byte.cfg \"$SINGLE_POD_IP\" \"$POD_IP_3\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_3\" \"$SINGLE_POD_NAME\" \"$POD_NAME_3\" $FOLDER_SINGLE_POD $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP

echo -e "\nCopy Root on Pod-Shared\n"
kubectl exec -i $POD_NAME_1 -- bash -c "/vagrant/ext/kites/scripts/linux/cp-root-to-pod-shared.sh"
kubectl exec -i $POD_NAME_2 -- bash -c "/vagrant/ext/kites/scripts/linux/cp-root-to-pod-shared.sh"
kubectl exec -i $POD_NAME_3 -- bash -c "/vagrant/ext/kites/scripts/linux/cp-root-to-pod-shared.sh"
kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/cp-root-to-pod-shared.sh"
