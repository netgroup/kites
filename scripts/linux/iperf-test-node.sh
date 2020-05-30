#!/bin/bash
IP_SRC=$1
IP_DEST=$2
POD_HOSTNAME_1=$3
POD_HOSTNAME_2=$4
POD_NAME_1=$5
POD_NAME_2=$6
ID_EXP=$7
TIMESTAMP=`date +%Y-%m-%d_%H-%M-%S`
TEMP_IP_SRC=$(sed -e "s/\r//g" <<< $IP_SRC)
TEMP_IP_DEST=$(sed -e "s/\r//g" <<< $IP_DEST)
NEW_IP_SRC=$(sed -e "s/\"//g" <<< $TEMP_IP_SRC) 
NEW_IP_DEST=$(sed -e "s/\"//g" <<< $TEMP_IP_DEST)
BASE_FOLDER=/vagrant/ext/kites/pod-shared
cd $BASE_FOLDER
echo -e "FROM VM_SRC: $POD_HOSTNAME_1 TO VM_DEST: $POD_HOSTNAME_2 \n" >> TCP_IPERF_NODE_OUTPUT.txt
echo -e "FROM POD_SRC: $POD_NAME_1 TO POD_DEST: $POD_NAME_2 \n" >> TCP_IPERF_NODE_OUTPUT.txt
echo -e "FROM IP_SRC: $IP_SRC TO IP_DEST: $IP_DEST - TIMESTAMP: $TIMESTAMP - ID_EXP: $ID_EXP \n" >> TCP_IPERF_NODE_OUTPUT.txt
echo -e "iperf3 -c ${NEW_IP_DEST} \n \n"
iperf3 -c $NEW_IP_DEST >> TCP_IPERF_NODE_OUTPUT.txt
echo -e "\n" >> TCP_IPERF_NODE_OUTPUT.txt
exit