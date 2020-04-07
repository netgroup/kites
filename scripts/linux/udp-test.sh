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
FOLDER_POD_1=pod1
FOLDER_POD_2=pod2
FOLDER_POD_3=pod3
FOLDER_SINGLE_POD=single-pod
INTER_EXPERIMENT_SLEEP=5
PPS=$1
BYTE=$2
ID_EXP=$3
echo -e "NETSNIFF TEST - ${BYTE}byte - ${PPS}pps\n" > NETSNIFF-${BYTE}byte-${PPS}pps.txt
echo -e "TRAFGEN TEST - ${BYTE}byte - ${PPS}pps\n" > TRAFGEN-${BYTE}byte-${PPS}pps.txt
echo -e "\n..................POD 1 TEST..................\n"
echo -e "----------------------------------------------\n\n"

if [ -d $BASE_FOLDER/$FOLDER_POD_1 ] 
then
    echo "Directory $BASE_FOLDER/$FOLDER_POD_1 exists." 
    cd $BASE_FOLDER/$FOLDER_POD_1
else
    echo "Error: Directory $BASE_FOLDER/$FOLDER_POD_1 doesn't exists."
    echo "Creating: Directory $BASE_FOLDER/$FOLDER_POD_1"
    mkdir -p $BASE_FOLDER/$FOLDER_POD_1 && cd $BASE_FOLDER/$FOLDER_POD_1
fi

kubectl exec -it $POD_NAME_1 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh samePod-${BYTE}byte.pcap \"$POD_IP_1\" \"$POD_IP_1\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_1\" \"$POD_NAME_1\" \"$POD_NAME_1\" $FOLDER_POD_1 $BYTE $PPS $ID_EXP" &
kubectl exec -it $POD_NAME_1 -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh samePod-${BYTE}byte.cfg \"$POD_IP_1\" \"$POD_IP_1\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_1\" \"$POD_NAME_1\" \"$POD_NAME_1\" $FOLDER_POD_1 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -it $POD_NAME_2 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh pod1ToPod2-${BYTE}byte.pcap \"$POD_IP_1\" \"$POD_IP_2\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_2\" \"$POD_NAME_1\" \"$POD_NAME_2\" $FOLDER_POD_1 $BYTE $PPS $ID_EXP" &
kubectl exec -it $POD_NAME_1 -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh pod1ToPod2-${BYTE}byte.cfg \"$POD_IP_1\" \"$POD_IP_2\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_2\" \"$POD_NAME_1\" \"$POD_NAME_2\" $FOLDER_POD_1 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -it $POD_NAME_3 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh pod1ToPod3-${BYTE}byte.pcap \"$POD_IP_1\" \"$POD_IP_3\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_3\" \"$POD_NAME_1\" \"$POD_NAME_3\" $FOLDER_POD_1 $BYTE $PPS $ID_EXP" &
kubectl exec -it $POD_NAME_1 -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh pod1ToPod3-${BYTE}byte.cfg \"$POD_IP_1\" \"$POD_IP_3\" \"$POD_HOSTNAME_1\" \"$POD_HOSTNAME_3\" \"$POD_NAME_1\" \"$POD_NAME_3\" $FOLDER_POD_1 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP

echo -e "\n..................POD 2 TEST..................\n"
echo -e "----------------------------------------------\n\n"

if [ -d $BASE_FOLDER/$FOLDER_POD_2 ] 
then
    echo "Directory $BASE_FOLDER/$FOLDER_POD_2 exists." 
    cd $BASE_FOLDER/$FOLDER_POD_2
else
    echo "Error: Directory $BASE_FOLDER/$FOLDER_POD_2 doesn't exists."
    echo "Creating: Directory $BASE_FOLDER/$FOLDER_POD_2"
    mkdir -p $BASE_FOLDER/$FOLDER_POD_2 && cd $BASE_FOLDER/$FOLDER_POD_2
fi

kubectl exec -it $POD_NAME_2 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh samePod-${BYTE}byte.pcap \"$POD_IP_2\" \"$POD_IP_2\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_2\" \"$POD_NAME_2\" \"$POD_NAME_2\" $FOLDER_POD_2 $BYTE $PPS $ID_EXP" &
kubectl exec -it $POD_NAME_2 -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh samePod-${BYTE}byte.cfg \"$POD_IP_2\" \"$POD_IP_2\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_2\" \"$POD_NAME_2\" \"$POD_NAME_2\" $FOLDER_POD_2 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -it $POD_NAME_1 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh pod2ToPod1-${BYTE}byte.pcap \"$POD_IP_2\" \"$POD_IP_1\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_1\" \"$POD_NAME_2\" \"$POD_NAME_1\" $FOLDER_POD_2 $BYTE $PPS $ID_EXP" &
kubectl exec -it $POD_NAME_2 -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh pod2ToPod1-${BYTE}byte.cfg \"$POD_IP_2\" \"$POD_IP_1\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_1\" \"$POD_NAME_2\" \"$POD_NAME_1\" $FOLDER_POD_2 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -it $POD_NAME_3 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh pod2ToPod3-${BYTE}byte.pcap \"$POD_IP_2\" \"$POD_IP_3\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_3\" \"$POD_NAME_2\" \"$POD_NAME_3\" $FOLDER_POD_2 $BYTE $PPS $ID_EXP" &
kubectl exec -it $POD_NAME_2 -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh pod2ToPod3-${BYTE}byte.cfg \"$POD_IP_2\" \"$POD_IP_3\" \"$POD_HOSTNAME_2\" \"$POD_HOSTNAME_3\" \"$POD_NAME_2\" \"$POD_NAME_3\" $FOLDER_POD_2 $BYTE $PPS"

echo -e "\n..................POD 3 TEST..................\n"
echo -e "----------------------------------------------\n\n"

if [ -d $BASE_FOLDER/$FOLDER_POD_3 ]
then
    echo "Directory $BASE_FOLDER/$FOLDER_POD_3 exists."
    cd $BASE_FOLDER/$FOLDER_POD_3
else
    echo "Error: Directory $BASE_FOLDER/$FOLDER_POD_3 doesn't exists."
    echo "Creating: Directory $BASE_FOLDER/$FOLDER_POD_3"
    mkdir -p $BASE_FOLDER/$FOLDER_POD_3 && cd $BASE_FOLDER/$FOLDER_POD_3
fi

kubectl exec -it $POD_NAME_3 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh samePod-${BYTE}byte.pcap \"$POD_IP_3\" \"$POD_IP_3\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_3\" \"$POD_NAME_3\" \"$POD_NAME_3\" $FOLDER_POD_3 $BYTE $PPS $ID_EXP" &
kubectl exec -it $POD_NAME_3 -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh samePod-${BYTE}byte.cfg \"$POD_IP_3\" \"$POD_IP_3\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_3\" \"$POD_NAME_3\" \"$POD_NAME_3\" $FOLDER_POD_3 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -it $POD_NAME_1 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh pod3ToPod1-${BYTE}byte.pcap \"$POD_IP_3\" \"$POD_IP_1\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_1\" \"$POD_NAME_3\" \"$POD_NAME_1\" $FOLDER_POD_3 $BYTE $PPS $ID_EXP" &
kubectl exec -it $POD_NAME_3 -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh pod3ToPod1-${BYTE}byte.cfg \"$POD_IP_3\" \"$POD_IP_1\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_1\" \"$POD_NAME_3\" \"$POD_NAME_1\" $FOLDER_POD_3 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -it $POD_NAME_2 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh pod3ToPod2-${BYTE}byte.pcap \"$POD_IP_3\" \"$POD_IP_2\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_2\" \"$POD_NAME_3\" \"$POD_NAME_2\" $FOLDER_POD_3 $BYTE $PPS $ID_EXP" &
kubectl exec -it $POD_NAME_3 -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh pod3ToPod2-${BYTE}byte.cfg \"$POD_IP_3\" \"$POD_IP_2\" \"$POD_HOSTNAME_3\" \"$POD_HOSTNAME_2\" \"$POD_NAME_3\" \"$POD_NAME_2\" $FOLDER_POD_3 $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP

echo -e "\n..................SINGLE POD TEST..................\n"
echo -e "----------------------------------------------\n\n"

if [ -d $BASE_FOLDER/$FOLDER_SINGLE_POD ]
then
    echo "Directory $BASE_FOLDER/$FOLDER_SINGLE_POD exists."
    cd $BASE_FOLDER/$FOLDER_SINGLE_POD
else
    echo "Error: Directory $BASE_FOLDER/$FOLDER_SINGLE_POD doesn't exists."
    echo "Creating: Directory $BASE_FOLDER/$FOLDER_SINGLE_POD"
    mkdir -p $BASE_FOLDER/$FOLDER_SINGLE_POD && cd $BASE_FOLDER/$FOLDER_SINGLE_POD
fi

kubectl exec -it $SINGLE_POD_NAME -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh SinglePodToSinglePod-${BYTE}byte.pcap \"$SINGLE_POD_IP\" \"$SINGLE_POD_IP\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_NAME\" \"$SINGLE_POD_NAME\" $FOLDER_SINGLE_POD $BYTE $PPS $ID_EXP" &
kubectl exec -it $SINGLE_POD_NAME -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh SinglePodToSinglePod-${BYTE}byte.cfg \"$SINGLE_POD_IP\" \"$SINGLE_POD_IP\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_NAME\" \"$SINGLE_POD_NAME\" $FOLDER_SINGLE_POD $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -it $POD_NAME_1 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh SinglePodToPod1-${BYTE}byte.pcap \"$SINGLE_POD_IP\" \"$POD_IP_1\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_1\" \"$SINGLE_POD_NAME\" \"$POD_NAME_1\" $FOLDER_SINGLE_POD $BYTE $PPS $ID_EXP" &
kubectl exec -it $SINGLE_POD_NAME -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh SinglePodToPod1-${BYTE}byte.cfg \"$SINGLE_POD_IP\" \"$POD_IP_1\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_1\" \"$SINGLE_POD_NAME\" \"$POD_NAME_1\" $FOLDER_SINGLE_POD $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -it $POD_NAME_2 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh SinglePodToPod2-${BYTE}byte.pcap \"$SINGLE_POD_IP\" \"$POD_IP_2\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_2\" \"$SINGLE_POD_NAME\" \"$POD_NAME_2\" $FOLDER_SINGLE_POD $BYTE $PPS $ID_EXP" &
kubectl exec -it $SINGLE_POD_NAME -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh SinglePodToPod2-${BYTE}byte.cfg \"$SINGLE_POD_IP\" \"$POD_IP_2\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_2\" \"$SINGLE_POD_NAME\" \"$POD_NAME_2\" $FOLDER_SINGLE_POD $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
kubectl exec -it $POD_NAME_3 -- bash -c "vagrant/ext/kites/scripts/linux/netsniff-test.sh SinglePodToPod3-${BYTE}byte.pcap \"$SINGLE_POD_IP\" \"$POD_IP_3\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_3\" \"$SINGLE_POD_NAME\" \"$POD_NAME_3\" $FOLDER_SINGLE_POD $BYTE $PPS $ID_EXP" &
kubectl exec -it $SINGLE_POD_NAME -- bash -c "vagrant/ext/kites/scripts/linux/trafgen-test.sh SinglePodToPod3-${BYTE}byte.cfg \"$SINGLE_POD_IP\" \"$POD_IP_3\" \"$SINGLE_POD_HOSTNAME\" \"$POD_HOSTNAME_3\" \"$SINGLE_POD_NAME\" \"$POD_NAME_3\" $FOLDER_SINGLE_POD $BYTE $PPS"
sleep $INTER_EXPERIMENT_SLEEP
