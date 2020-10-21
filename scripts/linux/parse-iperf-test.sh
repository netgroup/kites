#!/bin/bash
# CNI | Tipo di test | ID_EXP | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Out Unit | Incoming | Inc Unit | Passed | Pas Unit | TX Time | RX Time | TIMESTAMP
CNI=$1
iperf_input=$2
cd /vagrant/ext/kites/pod-shared/tests/"$CNI" || { echo "No such directory"; exit 1; }

for ((X = 0; X <= 297; X += 27)); do
    VM_SRC=$(awk 'NR=='"$X"+3' { print $3}' <"$iperf_input")
    #echo $VM_SRC
    VM_DEST=$(awk 'NR=='"$X"+3' { print $6}' <"$iperf_input")
    #echo $VM_DEST
    POD_SRC=$(awk 'NR=='"$X"+5' { print $3}' <"$iperf_input")
    #echo $POD_SRC
    POD_DEST=$(awk 'NR=='"$X"+5' { print $6}' <"$iperf_input")
    #echo $POD_DEST
    IP_SRC=$(awk 'NR=='"$X"+7' { print $3}' <"$iperf_input")
    #echo $IP_SRC
    IP_DEST=$(awk 'NR=='"$X"+7' { print $6}' <"$iperf_input")
    #echo $IP_DEST
    TIMESTAMP=$(awk 'NR=='"$X"+7' { print $9}' <"$iperf_input")
    #echo $IP_SRC
    ID_EXP=$(awk 'NR=='"$X"+7' { print $12}' <"$iperf_input")
    #echo $IP_DEST
    TX_TIME=$(awk 'NR=='"$X"+24' { print $3}' <"$iperf_input" | sed -n 's/\(^.[^$]*\)\(.\{5\}$\)/\2/p')
    #echo $TX_TIME
    OUTGOING=$(awk 'NR=='"$X"+24' { print $5}' <"$iperf_input")
    #echo $OUTGOING
    OUT_UNIT=$(awk 'NR=='"$X"+24' { print $6}' <"$iperf_input")
    #echo $OUT_UNIT
    RX_TIME=$(awk 'NR=='"$X"+25' { print $3}' <"$iperf_input" | sed -n 's/\(^.[^$]*\)\(.\{5\}$\)/\2/p')
    #echo $RX_TIME
    INCOMING=$(awk 'NR=='"$X"+25' { print $5}' <"$iperf_input")
    #echo $INCOMING
    INC_UNIT=$(awk 'NR=='"$X"+25' { print $6}' <"$iperf_input")
    #echo $INC_UNIT
    THROUGHPUT=$(awk 'NR=='"$X"+24' { print $7}' <"$iperf_input")
    #echo $THROUGHPUT
    THR_UNIT=$(awk 'NR=='"$X"+24' { print $8}' <"$iperf_input")
    #echo $THR_UNIT
    TEST_TYPE=$(awk 'NR=='"$X"+27' { print $1}' <"$iperf_input")
    #echo $TEST_TYPE
    /vagrant/ext/kites/scripts/linux/create-csv-from-iperf.sh "$CNI" $TEST_TYPE $ID_EXP $VM_SRC $VM_DEST $POD_SRC $POD_DEST $IP_SRC $IP_DEST $OUTGOING $OUT_UNIT $INCOMING $INC_UNIT $THROUGHPUT $THR_UNIT $TX_TIME $RX_TIME $TIMESTAMP
done
