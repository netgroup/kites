#!/bin/bash
KITES_HOME="/vagrant/ext/kites"
. ${KITES_HOME}/scripts/linux/utils/logging.sh
. ${KITES_HOME}/scripts/linux/utils/check-dependencies.sh
. ${KITES_HOME}/scripts/linux/cpu-monitoring.sh
HOSTNAME=$(hostname)
ID_EXP=$1
N=$2
IP_HOSTNAME=$3
V=$4
RUN_TEST_SAME=$5
RUN_TEST_SAMENODE=$6
RUN_TEST_DIFF=$7
RUN_TEST_CPU=$8
CPU_TEST="TCP"

#Start Iperf3 TCP Test
BASE_FOLDER="${KITES_HOME}/pod-shared"
cd $BASE_FOLDER
set -a
. ./pods_nodes.env
set +a
log_debug "TCP test node hostname: $HOSTNAME"
log_debug "$HOSTNAME to other PODS..."
log_debug "----------------------------------------------"
for ((pod_n = 1; pod_n <= $N; pod_n++)); do
   declare name1_pod="POD_NAME_$pod_n"
   if [ "$V" == "4" ]; then
      declare ip1_pod="POD_IP_$pod_n"
   else
      declare ip1_pod="POD_IP6_$pod_n"
   fi
   declare host1_pod="POD_HOSTNAME_$pod_n"

   if $RUN_TEST_CPU; then
      if ([ "$HOSTNAME" = "${!host1_pod//[$' ']/}" ] && $RUN_TEST_SAMENODE); then
         echo "samenode: $HOSTNAME == ${!host1_pod//[$' ']/}"
         start_cpu_monitor_nodes "$N" "samenode" 1 "${!host1_pod//[$' ']/}" $CPU_TEST "no" "NO_POD"
      elif ([ "$HOSTNAME" != "${!host1_pod//[$' ']/}" ] && $RUN_TEST_DIFFNODE); then
         echo "diffnode: $HOSTNAME != ${!host1_pod//[$' ']/}"
         start_cpu_monitor_nodes "$N" "diffnode" 2 "${HOSTNAME}TO${!host1_pod//[$' ']/}" $CPU_TEST "no" "NO_POD"
      fi
   fi

   ${KITES_HOME}/scripts/linux/iperf-test-node.sh "$IP_HOSTNAME" ${!ip1_pod} "$HOSTNAME" ${!host1_pod} "NO_POD" ${!name1_pod} "$ID_EXP"

   if $RUN_TEST_CPU; then
      if ([ "$HOSTNAME" = "${!host1_pod//[$' ']/}" ] && $RUN_TEST_SAMENODE); then
         stop_cpu_monitor_nodes "$N" "samenode" 1 "${!host1_pod//[$' ']/}" $CPU_TEST "no" "NO_POD"
      elif ([ "$HOSTNAME" != "${!host1_pod//[$' ']/}" ] && $RUN_TEST_DIFFNODE); then
         stop_cpu_monitor_nodes "$N" "diffnode" 2 "${HOSTNAME}TO${!host1_pod//[$' ']/}" $CPU_TEST "no" "NO_POD"
      fi
   fi
done

if $RUN_TEST_SAMENODE; then
   if [ "$V" == "4" ]; then
      declare single_pod_ip="SINGLE_POD_IP"
   else
      declare single_pod_ip="SINGLE_POD_IP6"
   fi
   if $RUN_TEST_CPU; then
         if [ "$HOSTNAME" = "$SINGLE_POD_HOSTNAME" ]; then
            # echo "samenode: $HOSTNAME == $SINGLE_POD_HOSTNAME"
            start_cpu_monitor_nodes "$N" "samenode" 1 "$SINGLE_POD_HOSTNAME" $CPU_TEST "no" "NO_POD"
         else
            # echo "diffnode: $HOSTNAME != ${SINGLE_POD_HOSTNAME}"
            start_cpu_monitor_nodes "$N" "diffnode" 2 "${HOSTNAME}TO${SINGLE_POD_HOSTNAME}" $CPU_TEST "no" "NO_POD"
         fi
   fi
   ${KITES_HOME}/scripts/linux/iperf-test-node.sh "$IP_HOSTNAME" ${!single_pod_ip} "$HOSTNAME" "$SINGLE_POD_HOSTNAME" "NO_POD" "$SINGLE_POD_NAME" "$ID_EXP"
   if $RUN_TEST_CPU; then
         if [ "$HOSTNAME" = "$SINGLE_POD_HOSTNAME" ]; then
            # echo "samenode: $HOSTNAME == $SINGLE_POD_HOSTNAME"
            stop_cpu_monitor_nodes "$N" "samenode" 1 "$SINGLE_POD_HOSTNAME" $CPU_TEST "no" "NO_POD"
         else
            # echo "diffnode: $HOSTNAME != ${SINGLE_POD_HOSTNAME}"
            stop_cpu_monitor_nodes "$N" "diffnode" 2 "${HOSTNAME}TO${SINGLE_POD_HOSTNAME}" $CPU_TEST "no" "NO_POD"
         fi
   fi
fi
exit
