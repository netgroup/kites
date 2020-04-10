#!/bin/bash
MAC_ADDR_POD_1=$1
MAC_ADDR_POD_2=$2
IP_ADDR_POD_1=$3
IP_ADDR_POD_2=$4
BYTE=$5
FILENAME=$6
FOLDER=$7
BASE_FOLDER=/vagrant/ext/kites/pod-shared
BYTE_FILENAME=$5
NEW_MAC_ADDR_POD_1=$(sed -e "s/\"//g" <<< $MAC_ADDR_POD_1) 
NEW_MAC_ADDR_POD_2=$(sed -e "s/\"//g" <<< $MAC_ADDR_POD_2) 
TEMP_IP_ADDR_POD_1=$(sed -e "s/\r//g" <<< $IP_ADDR_POD_1)
TEMP_IP_ADDR_POD_2=$(sed -e "s/\r//g" <<< $IP_ADDR_POD_2) 
NEW_IP_ADDR_POD_1=$(sed -e "s/\"//g" <<< $TEMP_IP_ADDR_POD_1) 
NEW_IP_ADDR_POD_2=$(sed -e "s/\"//g" <<< $TEMP_IP_ADDR_POD_2)
if [ -d "${BASE_FOLDER}/${FOLDER}" ] 
then
    echo "Directory ${BASE_FOLDER}/${FOLDER} exists." 
    cd ${BASE_FOLDER}/${FOLDER}
else
    echo "Error: Directory ${BASE_FOLDER}/${FOLDER} doesn't exists."
    echo "Creating: Directory ${BASE_FOLDER}/${FOLDER}"
    mkdir -p ${BASE_FOLDER}/${FOLDER} && cd ${BASE_FOLDER}/${FOLDER}
fi

# SAME POD 100 BYTE
echo "{
  ${NEW_MAC_ADDR_POD_2}
  ${NEW_MAC_ADDR_POD_1}
  0x08, 0x00,
  0b01000101, 0,
  const16(46),
  const16(2),
  0b01000000, 0,
  64,
  17,
  csumip(14, 33),
  ${NEW_IP_ADDR_POD_1},
  ${NEW_IP_ADDR_POD_2},
  const16(9),
  const16(6666),
  const16(26),
  const16(0),
  fill('B', $((BYTE-42))),
}" > ${FILENAME}-${BYTE_FILENAME}byte.cfg
