#!/bin/bash
KITES_HOME="/vagrant/ext/kites"
. ${KITES_HOME}/scripts/linux/utils/logging.sh
. ${KITES_HOME}/scripts/linux/utils/check-dependencies.sh
HOSTNAME=$(hostname)
ID_EXP=$1
N=$2
IP_HOSTNAME=$3
#Install package if not installed
sudo apt install -y iperf3 
#Start Iperf3 TCP Test
BASE_FOLDER=/vagrant/ext/kites/pod-shared
cd $BASE_FOLDER
set -a
. ./pods_nodes.env
set +a
log_debug "TCP test node hostname: $HOSTNAME, ip: $IP_HOSTNAME"
log_debug "$HOSTNAME to other PODS...\n"
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
   declare name1_pod="POD_NAME_$minion_n"
   declare ip1_pod="POD_IP_$minion_n"
   declare host1_pod="POD_HOSTNAME_$minion_n"
   ${KITES_HOME}/scripts/linux/iperf-test-node.sh \"$IP_HOSTNAME\" ${!ip1_pod} \"$HOSTNAME\" ${!host1_pod} "NO_POD" ${!name1_pod} $ID_EXP
done
${KITES_HOME}/scripts/linux/iperf-test-node.sh \"$IP_HOSTNAME\" \"$SINGLE_POD_IP\" \"$HOSTNAME\" \"$SINGLE_POD_HOSTNAME\" "NO_POD" \"$SINGLE_POD_NAME\" $ID_EXP
exit