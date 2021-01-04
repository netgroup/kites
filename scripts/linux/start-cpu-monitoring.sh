#!/bin/bash

KITES_HOME="/vagrant/ext/kites"
. ${KITES_HOME}/scripts/linux/utils/logging.sh
. ${KITES_HOME}/scripts/linux/cpu-monitoring.sh
start_cpu_monitor_node $1 $2 $3

# CONFIG=$1
# CONFIG_CODE=$2
# TEST_TYPE=$3
# CPU_TEST=$4
# BYTE=$5
# PPS=$6
# HOSTNAME=$(hostname)

# # saves its own pid
# echo $$ > /vagrant/ext/kites/cpu/cpu-$HOSTNAME-$CPU_TEST-${BYTE}-$CONFIG.pid

# INIZIO=$(date)
# echo "inizio $HOSTNAME configuration: $CONFIG test type: $TEST_TYPE"


# if [ -d "/vagrant/ext/kites/cpu/" ] 
# then
#     cd /vagrant/ext/kites/cpu/
# else
#     echo "Directory /vagrant/ext/kites/cpu/ doesn't exists."
#     echo "Creating: Directory /vagrant/ext/kites/cpu/"
#     mkdir -p /vagrant/ext/kites/cpu/ && cd /vagrant/ext/kites/cpu/
# fi
# echo "PPS, CONFIG, CONFIG_CODE, TEST_TYPE, DATE, CPU-${HOSTNAME}, %" >> cpu-$HOSTNAME-$CPU_TEST-${BYTE}bytes.csv

# # RUNTIME="$DURATION second"
# # ENDTIME=$(date -ud "$RUNTIME" +%s)
# # while [[ $(date -u +%s) -le $ENDTIME ]]

# sleep 2
# while true
# do 
# 	DATE=$(date "+%Y-%m-%d %H:%M:%S")
# 	CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
#     SINGLE_LINE="$PPS, $CONFIG, $CONFIG_CODE, $TEST_TYPE, $DATE, $CPU_USAGE, %"
# 	echo $SINGLE_LINE >> cpu-$HOSTNAME-$CPU_TEST-${BYTE}bytes.csv
#     #top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}' >> cpu-$HOSTNAME.txt
#     sleep 1
# done
