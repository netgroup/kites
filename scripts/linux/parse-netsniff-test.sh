#!/bin/bash
# CNI | Tipo di test | PPS | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time
CNI=$1
netsniff_input=$2
trafgen_input=$3

cd /vagrant/ext/kites/pod-shared/tests/$CNI

for (( X=0; X<=219; X+=18))
do
VM_SRC=$(awk 'NR=='$X+3' { print $3}' < $netsniff_input)
#echo $VM_SRC
VM_DEST=$(awk 'NR=='$X+3' { print $6}' < $netsniff_input)
#echo $VM_DEST 
POD_SRC=$(awk 'NR=='$X+5' { print $3}' < $netsniff_input)
#echo $POD_SRC
POD_DEST=$(awk 'NR=='$X+5' { print $6}' < $netsniff_input)
#echo $POD_DEST 
IP_SRC=$(awk 'NR=='$X+7' { print $3}' < $netsniff_input)
#echo $IP_SRC
IP_DEST=$(awk 'NR=='$X+7' { print $6}' < $netsniff_input)
#echo $IP_DEST 
TIMESTAMP=$(awk 'NR=='$X+7' { print $9}' < $netsniff_input)
#echo $IP_SRC
ID_EXP=$(awk 'NR=='$X+7' { print $12}' < $netsniff_input)
#echo $IP_DEST 
TEST_TYPE=$(awk 'NR=='$X+9' { print $1}' < $netsniff_input)
#echo $TEST_TYPE
PPS=$(awk 'NR=='$X+9' { print $4}' < $netsniff_input)
#echo $PPS 
BYTE=$(awk 'NR=='$X+9' { print $7}' < $netsniff_input)
#echo $PPS 
INCOMING=$(awk 'NR=='$X+13' { print $2}' < $netsniff_input)
#echo $INCOMING 
PASSED=$(awk 'NR=='$X+14' { print $2}' < $netsniff_input)
#echo $PASSED 
PASSED=$(awk 'NR=='$X+14' { print $2}' < $netsniff_input)
#echo $PASSED 
SEC_RX=$(awk 'NR=='$X+17' { print $2}' < $netsniff_input)
USEC_RX=$(awk 'NR=='$X+17' { print $4}' < $netsniff_input | sed 's/\(^...\).*/\1/')
RX_TIME=$SEC_RX.${USEC_RX}
#echo $RX_TIME 
/vagrant/ext/kites/scripts/linux/create-csv-from-netsniff.sh $CNI $TEST_TYPE $ID_EXP $PPS $VM_SRC $VM_DEST $POD_SRC $POD_DEST $IP_SRC $IP_DEST $INCOMING $PASSED $RX_TIME $TIMESTAMP $BYTE
done

for (( X=0; X<=228; X+=19))
do
OUTGOING=$(awk 'NR=='$X+16' { print $2}' < $trafgen_input)
#echo $OUTGOING
SEC_TX=$(awk 'NR=='$X+18' { print $2}' < $trafgen_input)
USEC_TX=$(awk 'NR=='$X+18' { print $4}' < $trafgen_input | sed 's/\(^...\).*/\1/')
TX_TIME=$SEC_TX.${USEC_TX}
#echo $TX_TIME 
/vagrant/ext/kites/scripts/linux/create-csv-from-trafgen.sh $CNI $OUTGOING $TX_TIME
done