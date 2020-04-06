#!/bin/bash
# CNI | Tipo di test | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Out Unit | Incoming | Inc Unit | Passed | Pass Unit | TX Time | RX Time
cd /vagrant/ext/kites/pod-shared/tests
CNI=$1
TEST_TYPE=$2
VM_SRC=$3
VM_DEST=$4
POD_SRC=$5
POD_DEST=$6
IP_SRC=$7
IP_DEST=$8
OUTGOING=$9
OUT_UNIT=${10}
INCOMING=${11}
INC_UNIT=${12}
PASSED=' '
PAS_UNIT=' '
RX_TIME=${15}
TX_TIME=${16}
echo "$CNI, $TEST_TYPE, $VM_SRC, $VM_DEST, $POD_SRC, $POD_DEST, $IP_SRC, $IP_DEST, $OUTGOING, $OUT_UNIT, $INCOMING, $INC_UNIT, $PASSED, $PAS_UNIT, $RX_TIME, $TX_TIME" >> iperf-tests.csv
