#!/bin/bash

KITES_HOME="/vagrant/ext/kites"
# TEST_TYPE=$1
# DURATION=$2
# CPU_TEST=$3
. ${KITES_HOME}/scripts/linux/utils/logging.sh
. ${KITES_HOME}/scripts/linux/cpu-monitoring.sh
start_cpu_monitor_node $1 $2 $3
