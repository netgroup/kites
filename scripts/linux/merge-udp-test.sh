#!/bin/bash
PPS=$1
BYTE=$2
BASE_FOLDER=/vagrant/ext/kites/pod-shared
cd $BASE_FOLDER
echo -e "NETSNIFF TEST - ${BYTE}byte - ${PPS}pps\n" > NETSNIFF-${BYTE}byte-${PPS}pps.txt
echo -e "TRAFGEN TEST - ${BYTE}byte - ${PPS}pps\n" > TRAFGEN-${BYTE}byte-${PPS}pps.txt

cd $BASE_FOLDER/pod1
cat NETSNIFF-${BYTE}byte-${PPS}pps.txt > temp_netsniff.txt
mv temp_netsniff.txt ..
rm NETSNIFF-${BYTE}byte-${PPS}pps.txt
cat TRAFGEN-${BYTE}byte-${PPS}pps.txt > temp_trafgen.txt
mv temp_trafgen.txt ..
rm TRAFGEN-${BYTE}byte-${PPS}pps.txt
cd .. 
cat temp_netsniff.txt >> NETSNIFF-${BYTE}byte-${PPS}pps.txt
rm temp_netsniff.txt
cat temp_trafgen.txt >> TRAFGEN-${BYTE}byte-${PPS}pps.txt
rm temp_trafgen.txt

cd $BASE_FOLDER/pod2
cat NETSNIFF-${BYTE}byte-${PPS}pps.txt > temp_netsniff.txt
mv temp_netsniff.txt ..
rm NETSNIFF-${BYTE}byte-${PPS}pps.txt
cat TRAFGEN-${BYTE}byte-${PPS}pps.txt > temp_trafgen.txt
mv temp_trafgen.txt ..
rm TRAFGEN-${BYTE}byte-${PPS}pps.txt
cd .. 
cat temp_netsniff.txt >> NETSNIFF-${BYTE}byte-${PPS}pps.txt
rm temp_netsniff.txt
cat temp_trafgen.txt >> TRAFGEN-${BYTE}byte-${PPS}pps.txt
rm temp_trafgen.txt

cd $BASE_FOLDER/pod3
cat NETSNIFF-${BYTE}byte-${PPS}pps.txt > temp_netsniff.txt
mv temp_netsniff.txt ..
rm NETSNIFF-${BYTE}byte-${PPS}pps.txt
cat TRAFGEN-${BYTE}byte-${PPS}pps.txt > temp_trafgen.txt
mv temp_trafgen.txt ..
rm TRAFGEN-${BYTE}byte-${PPS}pps.txt
cd .. 
cat temp_netsniff.txt >> NETSNIFF-${BYTE}byte-${PPS}pps.txt
rm temp_netsniff.txt
cat temp_trafgen.txt >> TRAFGEN-${BYTE}byte-${PPS}pps.txt
rm temp_trafgen.txt

cd $BASE_FOLDER/single-pod
cat NETSNIFF-${BYTE}byte-${PPS}pps.txt > temp_netsniff.txt
mv temp_netsniff.txt ..
rm NETSNIFF-${BYTE}byte-${PPS}pps.txt
cat TRAFGEN-${BYTE}byte-${PPS}pps.txt > temp_trafgen.txt
mv temp_trafgen.txt ..
rm TRAFGEN-${BYTE}byte-${PPS}pps.txt
cd .. 
cat temp_netsniff.txt >> NETSNIFF-${BYTE}byte-${PPS}pps.txt
rm temp_netsniff.txt
cat temp_trafgen.txt >> TRAFGEN-${BYTE}byte-${PPS}pps.txt
rm temp_trafgen.txt