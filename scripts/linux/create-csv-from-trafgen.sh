#!/bin/bash
# CNI | Tipo di test | PPS | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time
CNI=$1
OUTGOING=$2
TX_TIME=$3
cd /vagrant/ext/kites/pod-shared/tests/$CNI
echo "$OUTGOING, $TX_TIME" >> trafgen-tests.csv