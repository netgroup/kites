#!/bin/bash
calc() { awk "BEGIN{ printf \"%.2f\n\", $* }"; }
INPUT=$1
CNI=$2
shift 2
bytes=("$@")
for byte in "${bytes[@]}"
do
    echo "BYTE, PPS, CONFIG_CODE, CONFIG, RX/TX, TXED/TOTX, PacketRate" > udp_results_${CNI}_${byte}bytes.csv
done
OLDIFS=$IFS
IFS=','

[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
for byte in "${bytes[@]}"
do
    awk -F"," '$4=='$byte'' $INPUT > bytetemp.csv
    for (( pps=16800; pps<=19200; pps+=100 ))
    do
        echo $pps
        awk -F"," '$5=='$pps'' bytetemp.csv > temp.csv
        configs_names=("SamePod" "PodsOnSameNode" "PodsOnDiffNode")
        configs=("0" "1" "2")
        for config in "${configs[@]}"
        do
            echo "config= ${configs_names[$config]}"
            awk -F, '$19=='$config'' temp.csv > temp${configs_names[$config]}.csv
            incoming_tot=0
            outgoing_tot=0
            n=0
            while read cni test_type id_exp byte_n pps_n source_vm dest_vm source_pod dest_pod source_ip dest_ip outgoing incoming passed tx_time rx_time timestamp
            do
                incoming_tot=$((incoming + incoming_tot))
                # echo "i have $incoming incoming packets. Total: $incoming_tot"
                outgoing_tot=$((outgoing + outgoing_tot))
                # echo "i have $outgoing incoming packets. Total: $outgoing_tot"
                n=$((n + 1))
                # echo $n
            done < temp${configs_names[$config]}.csv
            incoming_avg=$(calc $incoming_tot/$n)
            outgoing_avg=$(calc $outgoing_tot/$n)
            # echo "avg_inc $incoming_avg"
            # echo "avg_out $outgoing_avg"
            rxtx_ratio=$(calc $incoming_avg/$outgoing_avg)
            totxpkt=$((pps*10))
            txedtx_ratio=$(calc $outgoing_avg/$totxpkt)
            real_pktrate=$(calc $totxpkt*$txedtx_ratio)
            # echo "real_pktrate $real_pktrate"
            echo "$byte, $pps, $config, ${configs_names[$config]}, $rxtx_ratio, $txedtx_ratio, $real_pktrate" >> udp_results_${CNI}_${byte}bytes.csv
            rm temp${configs_names[$config]}.csv
        done
        rm temp.csv
    done
    rm bytetemp.csv
done
IFS=$OLDIFS