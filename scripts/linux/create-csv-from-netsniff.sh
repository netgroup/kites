#!/bin/bash
# CNI | Tipo di test | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time
CNI=$1
TEST_TYPE=$2
ID_EXP=$3
PPS=$4
VM_SRC=$5
VM_DEST=$6
POD_SRC=$7
POD_DEST=$8
IP_SRC=$9
IP_DEST=${10}
INCOMING=${11}
PASSED=${12}
RX_TIME=${13}
TIMESTAMP=${14}
BYTE=${15}
cd /vagrant/ext/kites/pod-shared/tests/"$CNI" || {
    echo "No such directory"
    exit 1
}
echo "$CNI, $TEST_TYPE, $ID_EXP, $BYTE, $PPS, $VM_SRC, $VM_DEST, $POD_SRC, $POD_DEST, $IP_SRC, $IP_DEST, ,$INCOMING, $PASSED, ,$RX_TIME, $TIMESTAMP" >>netsniff-tests.csv
