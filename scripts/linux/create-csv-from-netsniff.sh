#!/bin/bash
# CNI | Tipo di test | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time
cd /vagrant/ext/kites/pod-shared/tests
CNI=$1
TEST_TYPE=$2
PPS=$3
VM_SRC=$4
VM_DEST=$5
POD_SRC=$6
POD_DEST=$7
IP_SRC=$8
IP_DEST=$9
INCOMING=${10}
PASSED=${11}
RX_TIME=${12}
echo "$CNI, $TEST_TYPE, $PPS, $VM_SRC, $VM_DEST, $POD_SRC, $POD_DEST, $IP_SRC, $IP_DEST, ,$INCOMING, $PASSED, ,$RX_TIME" >> netsniff-tests.csv