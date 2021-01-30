#!/bin/bash
PCAP=$1
IP_SRC=$2
IP_DEST=$3
POD_HOSTNAME_1=$4
POD_HOSTNAME_2=$5
POD_NAME_1=$6
POD_NAME_2=$7
FOLDER_POD=$8
BYTE=$9
PPS=${10}
ID_EXP=${11}
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
TEMP_IP_SRC=$(sed -e "s/\r//g" <<<$IP_SRC)
TEMP_IP_DEST=$(sed -e "s/\r//g" <<<$IP_DEST)
NEW_IP_SRC=$(sed -e "s/\"//g" <<<$TEMP_IP_SRC)
NEW_IP_DEST=$(sed -e "s/\"//g" <<<$TEMP_IP_DEST)
cd "/pod-shared/$FOLDER_POD" || {
    echo "Failure"
    exit 1
}
{
    echo -e "FROM VM_SRC: $POD_HOSTNAME_1 TO VM_DEST: $POD_HOSTNAME_2 \n"
    echo -e "FROM POD_SRC: $POD_NAME_1 TO POD_DEST: $POD_NAME_2 \n"
    echo -e "FROM IP_SRC: $IP_SRC TO IP_DEST: $IP_DEST - TIMESTAMP: $TIMESTAMP - ID_EXP: $ID_EXP \n"
    echo -e "$PCAP - PPS: ${PPS} - BYTE: ${BYTE}\n"
    timeout -s SIGINT 15 netsniff-ng --in eth0 --ring-size 64MiB --silent --no-sock-mem --filter "src host $NEW_IP_SRC and dst host $NEW_IP_DEST and inbound"
    echo -e "\n\n"
} >>"NETSNIFF-${BYTE}byte-${PPS}pps.txt"

exit
