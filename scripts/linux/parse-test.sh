#!/bin/bash
# CNI | Tipo di test | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Out Unit | Incoming | Inc Unit | Passed | Pas Unit | TX Time | RX Time
if [ -d "/vagrant/ext/kites/pod-shared/tests" ] 
then
    echo "Directory /vagrant/ext/kites/pod-shared/tests exists." 
    cd /vagrant/ext/kites/pod-shared/tests
else
    echo "Error: Directory /vagrant/ext/kites/pod-shared/tests doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/pod-shared/tests"
mkdir -p /vagrant/ext/kites/pod-shared/tests && cd /vagrant/ext/kites/pod-shared/tests
fi
echo "CNI, TEST_TYPE, PPS, VM_SRC, VM_DEST, POD_SRC, POD_DEST, IP_SRC, IP_DEST, OUTGOING, INCOMING, PASSED, TX_TIME, RX_TIME" > netsniff-tests.csv
echo "OUTGOING, TX_TIME" > trafgen-tests.csv
echo "CNI, TEST_TYPE, VM_SRC, VM_DEST, POD_SRC, POD_DEST, IP_SRC, IP_DEST, OUTGOING, OUT_UNIT, INCOMING, INC_UNIT, PASSED, PAS_UNIT, TX_TIME, RX_TIME" > iperf-tests.csv

/vagrant/ext/kites/scripts/linux/parse-netsniff-test.sh /vagrant/ext/kites/pod-shared/NETSNIFF-100byte-1000pps.txt /vagrant/ext/kites/pod-shared/TRAFGEN-100byte-1000pps.txt
/vagrant/ext/kites/scripts/linux/parse-netsniff-test.sh /vagrant/ext/kites/pod-shared/NETSNIFF-1000byte-1000pps.txt /vagrant/ext/kites/pod-shared/TRAFGEN-1000byte-1000pps.txt
/vagrant/ext/kites/scripts/linux/parse-netsniff-test.sh /vagrant/ext/kites/pod-shared/NETSNIFF-100byte-10000pps.txt /vagrant/ext/kites/pod-shared/TRAFGEN-100byte-10000pps.txt
/vagrant/ext/kites/scripts/linux/parse-netsniff-test.sh /vagrant/ext/kites/pod-shared/NETSNIFF-1000byte-10000pps.txt /vagrant/ext/kites/pod-shared/TRAFGEN-1000byte-10000pps.txt
/vagrant/ext/kites/scripts/linux/parse-netsniff-test.sh /vagrant/ext/kites/pod-shared/NETSNIFF-100byte-100000pps.txt /vagrant/ext/kites/pod-shared/TRAFGEN-100byte-100000pps.txt
/vagrant/ext/kites/scripts/linux/parse-netsniff-test.sh /vagrant/ext/kites/pod-shared/NETSNIFF-1000byte-100000pps.txt /vagrant/ext/kites/pod-shared/TRAFGEN-1000byte-100000pps.txt
awk -F, '{getline f1 <"trafgen-tests.csv" ;print f1,$1,$2,$3,$4,$5,$6,$7,$8,$9,$11,$12,$14}' OFS=, netsniff-tests.csv > temp.csv
awk -F, -v OFS=, '{ print $3,$4,$5,$6,$7,$8,$9,$10,$11,$1,$13,$14,$2}' temp.csv > netsniff-trafgen-tests.csv
rm temp.csv
/vagrant/ext/kites/scripts/linux/parse-iperf-test.sh /vagrant/ext/kites/pod-shared/TCP_IPERF_OUTPUT.txt
/vagrant/ext/kites/scripts/linux/parse-iperf-test-node.sh /vagrant/ext/kites/pod-shared/TCP_IPERF_NODE_OUTPUT.txt
