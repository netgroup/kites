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
NUM=$((PPS * 10))
echo "${CONFIG_FILE_UDP_TRAFFIC} ${IP_SRC} ${IP_DEST} ${POD_HOSTNAME_1} ${POD_HOSTNAME_2}"
echo "${POD_NAME_1} ${POD_NAME_2} ${FOLDER_POD} ${BYTE} ${PPS}"
if [ -d "/pod-shared/$FOLDER_POD" ]; then
    cd /pod-shared/"$FOLDER_POD"
else
    mkdir -p /pod-shared/"$FOLDER_POD" && cd /pod-shared/"$FOLDER_POD"
fi
echo "MALE MALE"
echo -e "FROM VM_SRC: $POD_HOSTNAME_1 TO VM_DEST: $POD_HOSTNAME_2 \n" >"$CONFIG_FILE_UDP_TRAFFIC".txt
echo "MALE MALE2"
echo -e "FROM POD_SRC: $POD_NAME_1 TO POD_DEST: $POD_NAME_2 \n" >>"$CONFIG_FILE_UDP_TRAFFIC".txt
echo "MALE MALE3"
echo -e "FROM IP_SRC: $IP_SRC TO IP_DEST: $IP_DEST \n" >>"$CONFIG_FILE_UDP_TRAFFIC".txt
echo "MALE MALE4"
echo -e "$CONFIG_FILE_UDP_TRAFFIC - PPS: ${PPS} \n" >>"$CONFIG_FILE_UDP_TRAFFIC".txt
echo "MALE MALE5"
#cat "$CONFIG_FILE_UDP_TRAFFIC"
trafgen --in "$CONFIG_FILE_UDP_TRAFFIC" --out eth0 --no-sock-mem --qdisc-path --rand --rate "${PPS}"pps
#timeout -s SIGINT 10 trafgen --in "$CONFIG_FILE_UDP_TRAFFIC" --out eth0 --no-sock-mem --qdisc-path --rand --rate "${PPS}"pps >>"$CONFIG_FILE_UDP_TRAFFIC".txt
#trafgen --in $CONFIG_FILE_UDP_TRAFFIC --out eth0 --no-sock-mem --qdisc-path --rand --rate ${PPS}pps --num ${NUM} >> $CONFIG_FILE_UDP_TRAFFIC.txt
echo -e "\n\n" >>"$CONFIG_FILE_UDP_TRAFFIC".txt
echo "Gatto"
cat "$CONFIG_FILE_UDP_TRAFFIC".txt >>TRAFGEN-"${BYTE}"byte-"${PPS}"pps.txt
rm "$CONFIG_FILE_UDP_TRAFFIC".txt
exit
