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
    for (( pps=17000; pps<=19000; pps+=200 ))
    do
        echo $pps
        awk -F"," '$5=='$pps'' bytetemp.csv > temp.csv
        configs_names=("SamePod" "PodsOnSameNode" "PodsOnDiffNode")
        configs=("0" "1" "2")
        for config in "${configs[@]}"
        do
            echo "config= ${configs_names[$config]}"
            awk -F, '$19=='$config'' temp.csv > temp${configs_names[$config]}.csv
            incoming_avg=$(awk -F',' '{sum+=$13; ++n} END { print sum/n }' < temp${configs_names[$config]}.csv)
            outgoing_avg=$(awk -F',' '{sum+=$12; ++n} END { print sum/n }' < temp${configs_names[$config]}.csv)
            rxtx_ratio=$(calc $incoming_avg/$outgoing_avg)
            totxpkt=$((pps*10))
            txedtx_ratio=$(calc $outgoing_avg/$totxpkt)
            real_pktrate=$(calc $pps*$txedtx_ratio)
            echo "$byte, $pps, $config, ${configs_names[$config]}, $rxtx_ratio, $txedtx_ratio, $real_pktrate" >> udp_results_${CNI}_${byte}bytes.csv
            rm temp${configs_names[$config]}.csv
        done
        rm temp.csv
    done
    rm bytetemp.csv
done
IFS=$OLDIFS