#!/bin/bash
CONFIG_FILE_UDP_TRAFFIC=$1
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
NUM=$((PPS * 10))

cd /pod-shared/$FOLDER_POD
echo -e "FROM VM_SRC: $POD_HOSTNAME_1 TO VM_DEST: $POD_HOSTNAME_2 \n" >$CONFIG_FILE_UDP_TRAFFIC.txt
echo -e "FROM POD_SRC: $POD_NAME_1 TO POD_DEST: $POD_NAME_2 \n" >>$CONFIG_FILE_UDP_TRAFFIC.txt
echo -e "FROM IP_SRC: $IP_SRC TO IP_DEST: $IP_DEST \n" >>$CONFIG_FILE_UDP_TRAFFIC.txt
echo -e "$CONFIG_FILE_UDP_TRAFFIC - PPS: ${PPS} - EXP: $ID_EXP - BYTE: $BYTE \n" >>$CONFIG_FILE_UDP_TRAFFIC.txt
# timeout -s SIGINT 10 trafgen --in $CONFIG_FILE_UDP_TRAFFIC --out eth0 --no-sock-mem --qdisc-path --rand --rate ${PPS}pps >> $CONFIG_FILE_UDP_TRAFFIC.txt
timeout -s SIGINT 10 trafgen --in $CONFIG_FILE_UDP_TRAFFIC --out eth0 --no-sock-mem --qdisc-path --rand --rate ${PPS}pps --num ${NUM} >>$CONFIG_FILE_UDP_TRAFFIC.txt
echo -e "\n\n" >>$CONFIG_FILE_UDP_TRAFFIC.txt
cat $CONFIG_FILE_UDP_TRAFFIC.txt >>TRAFGEN-${BYTE}byte-${PPS}pps.txt
rm $CONFIG_FILE_UDP_TRAFFIC.txt
exit
