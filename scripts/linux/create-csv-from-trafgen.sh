#!/bin/bash
# CNI | Tipo di test | PPS | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time
cd /vagrant/ext/kites/pod-shared/tests
OUTGOING=$1
TX_TIME=$2
echo "$OUTGOING, $TX_TIME" >> trafgen-tests.csv