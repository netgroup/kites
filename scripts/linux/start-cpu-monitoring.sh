#!/bin/bash

KITES_HOME="/vagrant/ext/kites"
. ${KITES_HOME}/scripts/linux/utils/logging.sh
. ${KITES_HOME}/scripts/linux/cpu-monitoring.sh
start_cpu_monitor_node $1 $2 $3 $4 $5 $6
