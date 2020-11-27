#!/bin/bash
# CNI | Tipo di test | PPS | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time
CNI=$1
OUTGOING=$2
TX_TIME=$3
VM_SRC=$4
VM_DEST=$5
POD_SRC=$6
POD_DEST=$7
PPS=$8
cd /vagrant/ext/kites/pod-shared/tests/$CNI
echo "$OUTGOING, $TX_TIME, $VM_SRC, $VM_DEST, $POD_SRC, $POD_DEST, $PPS" >> trafgen-tests.csv