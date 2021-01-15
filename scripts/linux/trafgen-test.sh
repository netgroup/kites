#!/bin/bash
CONFIG_FILE_UDP_TRAFFIC=$1
# echo " CONFIG_FILE_UDP_TRAFFIC = $CONFIG_FILE_UDP_TRAFFIC"
IP_SRC=$2
# echo " IP_SRC = $IP_SRC"
IP_DEST=$3
# echo " IP_DEST = $IP_DEST"
POD_HOSTNAME_1=$4
# echo " POD_HOSTNAME_1 = $POD_HOSTNAME_1"
POD_HOSTNAME_2=$5
# echo " POD_HOSTNAME_2 = $POD_HOSTNAME_2"
POD_NAME_1=$6
# echo " POD_NAME_1 = $POD_NAME_1"
POD_NAME_2=$7
# echo " POD_NAME_2 = $POD_NAME_2"
FOLDER_POD=$8
# echo " FOLDER_POD = $FOLDER_POD"
BYTE=$9
# echo " BYTE = $BYTE"
PPS=${10}
# echo " PPS = $PPS"
NUM=$((PPS*10))

cd /pod-shared/$FOLDER_POD
echo -e "FROM VM_SRC: $POD_HOSTNAME_1 TO VM_DEST: $POD_HOSTNAME_2 \n" > $CONFIG_FILE_UDP_TRAFFIC.txt
echo -e "FROM POD_SRC: $POD_NAME_1 TO POD_DEST: $POD_NAME_2 \n" >> $CONFIG_FILE_UDP_TRAFFIC.txt
echo -e "FROM IP_SRC: $IP_SRC TO IP_DEST: $IP_DEST \n" >> $CONFIG_FILE_UDP_TRAFFIC.txt
echo -e "$CONFIG_FILE_UDP_TRAFFIC - PPS: ${PPS} \n" >> $CONFIG_FILE_UDP_TRAFFIC.txt

timeout -s SIGINT 10 trafgen --in $CONFIG_FILE_UDP_TRAFFIC --out eth0 --no-sock-mem --qdisc-path --rand --rate ${PPS}pps >> $CONFIG_FILE_UDP_TRAFFIC.txt
#trafgen --in $CONFIG_FILE_UDP_TRAFFIC --out eth0 --no-sock-mem --qdisc-path --rand --rate ${PPS}pps --num ${NUM} >> $CONFIG_FILE_UDP_TRAFFIC.txt

echo -e "\n\n" >> $CONFIG_FILE_UDP_TRAFFIC.txt
cat $CONFIG_FILE_UDP_TRAFFIC.txt >> TRAFGEN-${BYTE}byte-${PPS}pps.txt
rm $CONFIG_FILE_UDP_TRAFFIC.txt
exit
