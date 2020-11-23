#!/bin/bash
calc() { awk "BEGIN{ printf \"%.2f\n\", $* }"; }
echo "PPS, CONFIG_CODE, CONFIG, RX/TX, TXED/TOTX" >> udp_results.csv
INPUT=$1
OLDIFS=$IFS
IFS=','

[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }

for (( pps=10000; pps<=60000; pps+=5000 ))
do
    echo $pps
    awk -F"," '$5=='$pps'' $INPUT > temp.csv
    configs_names=("SamePod" "PodsOnSameNode" "PodsOnDiffNode")
    configs=("0" "1" "2")
    for config in "${configs[@]}"
    do
        echo "config= ${configs_names[$config]}"
        awk -F, '$19=='$config'' temp.csv > temp${configs_names[$config]}.csv
        incoming_tot=0
        outgoing_tot=0
        n=0
        while read cni test_type id_exp byte pps_n source_vm dest_vm source_pod dest_pod source_ip dest_ip outgoing out_unit incoming inc_unit passed pass_unit tx_time rx_time timestamp
        do
            echo "FOR ${configs_names[$config]}: i have $incoming incoming packets"
            echo "FOR ${configs_names[$config]}: i have $outgoing outgoing packets"
            incoming_tot=$((incoming + incoming_tot))
            outgoing_tot=$((outgoing + outgoing_tot))
            n=$((n + 1))
            echo "incoming tot: $incoming_tot"
            echo "outgoing tot: $outgoing_tot"
            echo "n: $n"
        done < temp${configs_names[$config]}.csv
        incoming_avg=$(calc $incoming_tot/$n)
        outgoing_avg=$(calc $outgoing_tot/$n)
        echo "avg_inc $incoming_avg"
        echo "avg_out $outgoing_avg"
        rxtx_ratio=$(calc $incoming_avg/$outgoing_avg)
        totxpkt=$((pps*10))
        txedtx_ratio=$(calc $outgoing_avg/$totxpkt)
        echo "RATIO: $rxtx_ratio"
        echo "$pps, $config, ${configs_names[$config]}, $rxtx_ratio, $txedtx_ratio" >> udp_results.csv
        rm temp${configs_names[$config]}.csv
    done
    rm temp.csv
done
IFS=$OLDIFS