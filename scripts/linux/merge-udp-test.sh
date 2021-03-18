#!/bin/bash
PPS=$1
BYTE=$2
N=$3
RUN_TEST_SAMENODE=$4
BASE_FOLDER=/vagrant/ext/kites/pod-shared
cd $BASE_FOLDER
echo -e "NETSNIFF TEST - ${BYTE}byte - ${PPS}pps\n" > NETSNIFF-${BYTE}byte-${PPS}pps.txt
echo -e "TRAFGEN TEST - ${BYTE}byte - ${PPS}pps\n" > TRAFGEN-${BYTE}byte-${PPS}pps.txt


for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
    cd $BASE_FOLDER/pod$minion_n || continue
    cat NETSNIFF-${BYTE}byte-${PPS}pps.txt > temp_netsniff.txt
    mv temp_netsniff.txt ..
    #rm NETSNIFF-${BYTE}byte-${PPS}pps.txt
    cat TRAFGEN-${BYTE}byte-${PPS}pps.txt > temp_trafgen.txt
    mv temp_trafgen.txt ..
    #rm TRAFGEN-${BYTE}byte-${PPS}pps.txt
    cd .. 
    cat temp_netsniff.txt >> NETSNIFF-${BYTE}byte-${PPS}pps.txt
    rm temp_netsniff.txt
    cat temp_trafgen.txt >> TRAFGEN-${BYTE}byte-${PPS}pps.txt
    rm temp_trafgen.txt
done

if $RUN_TEST_SAMENODE; then
    cd $BASE_FOLDER/single-pod
    cat NETSNIFF-${BYTE}byte-${PPS}pps.txt > temp_netsniff.txt
    mv temp_netsniff.txt ..
    #rm NETSNIFF-${BYTE}byte-${PPS}pps.txt
    cat TRAFGEN-${BYTE}byte-${PPS}pps.txt > temp_trafgen.txt
    mv temp_trafgen.txt ..
    #rm TRAFGEN-${BYTE}byte-${PPS}pps.txt
    cd .. 
    cat temp_netsniff.txt >> NETSNIFF-${BYTE}byte-${PPS}pps.txt
    rm temp_netsniff.txt
    cat temp_trafgen.txt >> TRAFGEN-${BYTE}byte-${PPS}pps.txt
    rm temp_trafgen.txt
fi