#!/bin/bash
echo "PPS, CONFIG_CODE, CONFIG, RX/TX, TXED/TOTX, PacketRate" > udp_throughput.csv
INPUT=$1
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }

configs_names=("SamePod" "PodsOnSameNode" "PodsOnDiffNode")
configs=("0" "1" "2")
for config in "${configs[@]}"
do
    echo "for ${configs_names[$config]} ($config)"
    awk -F, '$2=='$config'' $INPUT > temp${configs_names[$config]}.csv

    #this takes the packet rate with the MAXIMUM rx/tx
    awk -F, 'NR==1{s=m=$4}{a[$4]=$0;m=($4>m)?$4:m;s=($4<s)?$4:s}END{print a[m]}' temp${configs_names[$config]}.csv >> udp_throughput_max.csv
    
    #this takes the maximum packet rate which guarantees a rx/tx>0.95
    awk -F, '$4 > 0.95' temp${configs_names[$config]}.csv > temp.csv
    sort -k4 temp.csv > sortedtemp.csv
    awk -F, 'NR==1{s=m=$6}{a[$6]=$0;m=($6>m)?$6:m;s=($6<s)?$6:s}END{print a[m]}' sortedtemp.csv >> udp_throughput.csv
    rm temp${configs_names[$config]}.csv
    rm sortedtemp.csv
    rm temp.csv
done