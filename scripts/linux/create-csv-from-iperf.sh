#!/bin/bash
# CNI | Tipo di test | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Out Unit | Incoming | Inc Unit | Passed | Pass Unit | TX Time | RX Time
CNI=$1
TEST_TYPE=$2
ID_EXP=$3
VM_SRC=$4
VM_DEST=$5
POD_SRC=$6
POD_DEST=$7
IP_SRC=$8
IP_DEST=$9
OUTGOING=${10}
OUT_UNIT=${11}
INCOMING=${12}
INC_UNIT=${13}
PASSED=' '
PAS_UNIT=' '
RX_TIME=${16}
TX_TIME=${17}
TIMESTAMP=${18}
cd /vagrant/ext/kites/pod-shared/tests/$CNI
echo "$CNI, $TEST_TYPE, $ID_EXP, $VM_SRC, $VM_DEST, $POD_SRC, $POD_DEST, $IP_SRC, $IP_DEST, $OUTGOING, $OUT_UNIT, $INCOMING, $INC_UNIT, $PASSED, $PAS_UNIT, $RX_TIME, $TX_TIME, $TIMESTAMP" >> iperf-tests.csv
