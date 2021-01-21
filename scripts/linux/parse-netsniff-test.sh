#!/bin/bash
# CNI | Tipo di test | PPS | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time

. ${KITES_HOME}/scripts/linux/utils/csv.sh

CNI=$1
netsniff_input=$2
trafgen_input=$3
ID_EXP=$4
OLDIFS=$IFS
IFS=', '


cd ${KITES_HOME}/pod-shared/tests/$CNI

comb_t=$(wc -l $trafgen_input | awk '{ print $1 }')
declare end_t=$((comb_t - 19))

for (( X=0; X<=$end_t; X+=19))
do
    VM_SRC=$(awk 'NR=='$X+3' { print $3}' < $trafgen_input)
    # echo $VM_SRC
    VM_DEST=$(awk 'NR=='$X+3' { print $6}' < $trafgen_input)
    # echo $VM_DEST 
    POD_SRC=$(awk 'NR=='$X+5' { print $3}' < $trafgen_input)
    # echo $POD_SRC
    POD_DEST=$(awk 'NR=='$X+5' { print $6}' < $trafgen_input)
    # echo $POD_DEST
    OUTGOING=$(awk 'NR=='$X+16' { print $2}' < $trafgen_input)
    PPS=$(awk 'NR=='$X+9' { print $4}' < $trafgen_input)
    ID_EXP=$(awk 'NR=='$X+9' { print $7}' < $trafgen_input)
    #echo $OUTGOING
    SEC_TX=$(awk 'NR=='$X+18' { print $2}' < $trafgen_input)
    USEC_TX=$(awk 'NR=='$X+18' { print $4}' < $trafgen_input | sed 's/\(^...\).*/\1/')
    TX_TIME=$SEC_TX.${USEC_TX}
    #echo $TX_TIME 
    append_csv_from_trafgen $CNI $OUTGOING $TX_TIME $VM_SRC $VM_DEST $POD_SRC $POD_DEST $PPS $ID_EXP
done


# declare n_plus=$((N + 1))
# declare end=$n_plus*$N
comb_n=$(wc -l $netsniff_input | awk '{ print $1 }')
declare end_n=$((comb_n - 18))


cd ${KITES_HOME}/pod-shared/tests/$CNI
echo "im in parse netsniff"

for (( X=0; X<=$end_n; X+=18))
do
    #echo "X = $X"
    VM_SRC=$(awk 'NR=='$X+3' { print $3}' < $netsniff_input)
    # echo $VM_SRC
    VM_DEST=$(awk 'NR=='$X+3' { print $6}' < $netsniff_input)
    # echo $VM_DEST 
    POD_SRC=$(awk 'NR=='$X+5' { print $3}' < $netsniff_input)
    # echo $POD_SRC
    POD_DEST=$(awk 'NR=='$X+5' { print $6}' < $netsniff_input)
    # echo $POD_DEST 
    IP_SRC=$(awk 'NR=='$X+7' { print $3}' < $netsniff_input)
    # echo $IP_SRC
    IP_DEST=$(awk 'NR=='$X+7' { print $6}' < $netsniff_input)
    # echo $IP_DEST 
    TIMESTAMP=$(awk 'NR=='$X+7' { print $9}' < $netsniff_input)
    #echo $IP_SRC
    ID_EXP=$(awk 'NR=='$X+7' { print $12}' < $netsniff_input)
    #echo $IP_DEST 
    TEST_TYPE=$(awk 'NR=='$X+9' { print $1}' < $netsniff_input)
    #echo $TEST_TYPE
    PPS=$(awk 'NR=='$X+9' { print $4}' < $netsniff_input)
    #echo $PPS 
    BYTE=$(awk 'NR=='$X+9' { print $7}' < $netsniff_input)
    # echo $PPS 
    INCOMING=$(awk 'NR=='$X+13' { print $2}' < $netsniff_input)
    #echo $INCOMING 
    PASSED=$(awk 'NR=='$X+14' { print $2}' < $netsniff_input)
    #echo $PASSED 
    SEC_RX=$(awk 'NR=='$X+17' { print $2}' < $netsniff_input)
    USEC_RX=$(awk 'NR=='$X+17' { print $4}' < $netsniff_input | sed 's/\(^...\).*/\1/')
    RX_TIME=$SEC_RX.${USEC_RX}
    #echo $RX_TIME 
    if [[ "$POD_SRC" != "$POD_DEST" ]]
    then
        if [[ "$VM_SRC" != "$VM_DEST" ]]
        then
            CONFIG="diffnode"
            CONFIG_CODE=2
        else
            CONFIG="samenode"
            CONFIG_CODE=1
        fi
    else
        CONFIG="samepod"
        CONFIG_CODE=0
    fi  

    while read outgoing tx_time vm_src vm_dest pod_src pod_dest pps id_exp
    do
        if [ "$pps" -eq "$PPS" ]; then
            if [ "$vm_src" = "$VM_SRC" ] && [ "$vm_dest" = "$VM_DEST" ] && [ "$pod_src" = "$POD_SRC" ] && [ "$pod_dest" = "$POD_DEST" ] && [ "$id_exp" = "$ID_EXP" ]; then
                OUTGOING=$outgoing
                # echo "outgoing= $OUTGOING"
                TX_TIME=$tx_time
                # echo "txtime = $TX_TIME"
            fi
        fi
    done < trafgen-tests.csv

    # OUTGOING=$(awk -F',' '$3 ~ /'$VM_SRC'/ && $4 ~ /'$VM_DEST'/ && $5 ~ /'$POD_SRC'/ && $6 ~ /'$POD_DEST'/  { print $1 }' trafgen-tests.csv)
    # TX_TIME=$(awk -F',' '$3 ~ /'$VM_SRC'/ && $4 ~ /'$VM_DEST'/ && $5 ~ /'$POD_SRC'/ && $6 ~ /'$POD_DEST'/  { print $2 }' trafgen-tests.csv)

    #echo $CONFIG
    append_csv_from_netsniff $CNI $TEST_TYPE $ID_EXP $PPS $VM_SRC $VM_DEST $POD_SRC $POD_DEST $IP_SRC $IP_DEST $INCOMING $PASSED $RX_TIME $TIMESTAMP $BYTE $CONFIG $CONFIG_CODE $OUTGOING $TX_TIME
done

IFS=$OLDIFS
