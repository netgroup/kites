#!/bin/bash
# CNI | Tipo di test | PPS | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time
CNI=$1
netsniff_input=$2
trafgen_input=$3
N=$4
OLDIFS=$IFS
IFS=', '


cd /vagrant/ext/kites/pod-shared/tests/$CNI

comb_t=$(wc -l $trafgen_input | awk '{ print $1 }')
declare end_t=$((comb_t - 19))

for (( X=0; X<=$end_t; X+=19))
do
    VM_SRC=$(awk 'NR=='$X+3' { print $3}' < $trafgen_input)
    echo $VM_SRC
    VM_DEST=$(awk 'NR=='$X+3' { print $6}' < $trafgen_input)
    echo $VM_DEST 
    POD_SRC=$(awk 'NR=='$X+5' { print $3}' < $trafgen_input)
    echo $POD_SRC
    POD_DEST=$(awk 'NR=='$X+5' { print $6}' < $trafgen_input)
    echo $POD_DEST
    OUTGOING=$(awk 'NR=='$X+16' { print $2}' < $trafgen_input)
    PPS=$(awk 'NR=='$X+9' { print $4}' < $trafgen_input)
    #echo $OUTGOING
    SEC_TX=$(awk 'NR=='$X+18' { print $2}' < $trafgen_input)
    USEC_TX=$(awk 'NR=='$X+18' { print $4}' < $trafgen_input | sed 's/\(^...\).*/\1/')
    TX_TIME=$SEC_TX.${USEC_TX}
    #echo "transmission time, lo trova?"
    #echo $TX_TIME 
    /vagrant/ext/kites/scripts/linux/create-csv-from-trafgen.sh $CNI $OUTGOING $TX_TIME $VM_SRC $VM_DEST $POD_SRC $POD_DEST $PPS
done


# declare n_plus=$((N + 1))
# declare end=$n_plus*$N
comb_n=$(wc -l $netsniff_input | awk '{ print $1 }')
declare end_n=$((comb_n - 18))


cd /vagrant/ext/kites/pod-shared/tests/$CNI
echo "im in parse netsniff"

for (( X=0; X<=$end_n; X+=18))
do
    #echo "X = $X"
    VM_SRC=$(awk 'NR=='$X+3' { print $3}' < $netsniff_input)
    echo $VM_SRC
    VM_DEST=$(awk 'NR=='$X+3' { print $6}' < $netsniff_input)
    echo $VM_DEST 
    POD_SRC=$(awk 'NR=='$X+5' { print $3}' < $netsniff_input)
    echo $POD_SRC
    POD_DEST=$(awk 'NR=='$X+5' { print $6}' < $netsniff_input)
    echo $POD_DEST 
    IP_SRC=$(awk 'NR=='$X+7' { print $3}' < $netsniff_input)
    echo $IP_SRC
    IP_DEST=$(awk 'NR=='$X+7' { print $6}' < $netsniff_input)
    echo $IP_DEST 
    TIMESTAMP=$(awk 'NR=='$X+7' { print $9}' < $netsniff_input)
    #echo $IP_SRC
    ID_EXP=$(awk 'NR=='$X+7' { print $12}' < $netsniff_input)
    #echo $IP_DEST 
    TEST_TYPE=$(awk 'NR=='$X+9' { print $1}' < $netsniff_input)
    #echo $TEST_TYPE
    PPS=$(awk 'NR=='$X+9' { print $4}' < $netsniff_input)
    #echo $PPS 
    BYTE=$(awk 'NR=='$X+9' { print $7}' < $netsniff_input)
    echo $PPS 
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
            CONFIG="PodsOnDiffNode"
            CONFIG_CODE=2
        else
            CONFIG="PodsOnSameNode"
            CONFIG_CODE=1
        fi
    else
        CONFIG="SamePod"
        CONFIG_CODE=0
    fi   

    while read outgoing tx_time vm_src vm_dest pod_src pod_dest pps
    do
        # echo "PRIMA DELL'IF outoging = $outgoing di $vm_src $vm_dest $pod_src $pod_dest $pps"
        # echo "ma vale lo scope di $VM_SRC e $VM_DEST qui dentro?"
        # if [ "$VM_SRC" = "$vm_src" ]; then
        #     echo "le vm sono uguali: $VM_SRC == $vm_src"
        # elif [[ "$vm_dest" == "$VM_DEST" ]]; then
        #     echo "$vm_dest == $VM_DEST"
        # elif [[ $VM_SRC == $vm_src ]]; then
        #     echo "te sta bene?!"
        # elif [ $VM_SRC = $vm_src ]; then
        #     echo "te prego"
        # else
        #     echo "niente da fa"
        # fi
        if [ "$pps" -eq "$PPS" ]; then
            if [ "$vm_src" = "$VM_SRC" ] && [ "$vm_dest" = "$VM_DEST" ] && [ "$pod_src" = "$POD_SRC" ] && [ "$pod_dest" = "$POD_DEST" ]; then
                # echo "$vm_src == $VM_SRC" && echo "$vm_dest == $VM_DEST" &&  echo "$pod_src == $POD_SRC" && echo "$pod_dest == $POD_DEST" && echo "$pps == $PPS"
                # echo "ougoing $outgoing di $vm_src $vm_dest $pod_src $pod_dest $pps"
                OUTGOING=$outgoing
                echo "outgoing= $OUTGOING"
                TX_TIME=$tx_time
                echo "txtime = $TX_TIME"
            else
                echo "non gli è piaciuto"
            fi
        fi
    done < trafgen-tests.csv

    #echo $CONFIG
    /vagrant/ext/kites/scripts/linux/create-csv-from-netsniff.sh $CNI $TEST_TYPE $ID_EXP $PPS $VM_SRC $VM_DEST $POD_SRC $POD_DEST $IP_SRC $IP_DEST $INCOMING $PASSED $RX_TIME $TIMESTAMP $BYTE $CONFIG $CONFIG_CODE $OUTGOING $TX_TIME
done

IFS=$OLDIFS
