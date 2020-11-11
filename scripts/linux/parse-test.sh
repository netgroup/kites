#!/bin/bash
CNI=$1
if [ -d "/vagrant/ext/kites/pod-shared/tests/$CNI" ] 
then
    cd /vagrant/ext/kites/pod-shared/tests/$CNI
else
    echo "Directory /vagrant/ext/kites/pod-shared/tests/$CNI doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/pod-shared/tests/$CNI"
    mkdir -p /vagrant/ext/kites/pod-shared/tests/$CNI && cd /vagrant/ext/kites/pod-shared/tests/$CNI
fi
echo "CNI, TEST_TYPE, ID_EXP, BYTE, PPS, VM_SRC, VM_DEST, POD_SRC, POD_DEST, IP_SRC, IP_DEST, OUTGOING, INCOMING, PASSED, TX_TIME, RX_TIME, TIMESTAMP" > netsniff-tests.csv
echo "OUTGOING, TX_TIME" > trafgen-tests.csv
echo "CNI, TEST_TYPE, ID_EXP, VM_SRC, VM_DEST, POD_SRC, POD_DEST, IP_SRC, IP_DEST, OUTGOING, OUT_UNIT, INCOMING, INC_UNIT, THROUGHPUT, THR_UNIT, TX_TIME, RX_TIME, TIMESTAMP" > iperf-tests.csv

# CNI | Tipo di test | ID_EXP | PPS | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time | TIMESTAMP
for (( pps=10000; pps<=60000; pps+=5000 ))
do
    /vagrant/ext/kites/scripts/linux/parse-netsniff-test.sh $CNI /vagrant/ext/kites/pod-shared/NETSNIFF-1000byte-${pps}pps.txt /vagrant/ext/kites/pod-shared/TRAFGEN-1000byte-${pps}pps.txt
done
awk -F, '{getline f1 <"trafgen-tests.csv" ;print f1,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$13,$14,$16,$17}' OFS=, netsniff-tests.csv > temp.csv
awk -F, -v OFS=, '{ print $3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$1,$14,$15,$2,$16,$17}' temp.csv > netsniff-trafgen-tests.csv
rm temp.csv
# CNI | Tipo di test | ID_EXP | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Out Unit | Incoming | Inc Unit | Passed | Pas Unit | TX Time | RX Time | TIMESTAMP

#Uncomment also in make-net-test.sh: TCP TEST FOR PODS AND NODES WITH IPERF3
/vagrant/ext/kites/scripts/linux/parse-iperf-test.sh $CNI "/vagrant/ext/kites/pod-shared/TCP_IPERF_OUTPUT.txt"
/vagrant/ext/kites/scripts/linux/parse-iperf-test-node.sh $CNI "/vagrant/ext/kites/pod-shared/TCP_IPERF_NODE_OUTPUT.txt"

if [ -d "/vagrant/ext/kites/tests/" ] 
then
    mv /vagrant/ext/kites/pod-shared/tests/$CNI /vagrant/ext/kites/tests/
else
    echo "Directory /vagrant/ext/kites/tests/ doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/tests/"
    mkdir -p /vagrant/ext/kites/tests/
    mv /vagrant/ext/kites/pod-shared/tests/$CNI /vagrant/ext/kites/tests/
fi