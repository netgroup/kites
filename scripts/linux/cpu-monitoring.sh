#!/bin/bash

function start_cpu_monitor_nodes() {
	log_inf "Start CPU monitoring: $1 minions, type $2, cpu test $4, duration $3"
	N=$1
	TEST_TYPE=$2
	DURATION=$3
	CPU_TEST=$4
	log_inf "Start CPU monitoring from master."
	${KITES_HOME}/scripts/linux/start-cpu-monitoring.sh "$TEST_TYPE" $DURATION $CPU_TEST
	log_inf "Start CPU monitoring from minions."
	for ((minion_n = 1; minion_n <= $N; minion_n++)); do
		# TODO we shoult do it in a differet way
		sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-${minion_n}.k8s-play.local "${KITES_HOME}/scripts/linux/start-cpu-monitoring.sh \"$TEST_TYPE\" $DURATION \"$CPU_TEST\""
	done
}

function start_cpu_monitor_node() {
	TEST_TYPE=$1
	DURATION=$2
	CPU_TEST=$3
	HOSTNAME=$(hostname)
	log_debug "Start CPU monitoring - node: $HOSTNAME - test type: $TEST_TYPE - duration: $DURATION"
	if [ ! -d "${KITES_HOME}/cpu/" ]; then
		log_debug "Directory ${KITES_HOME}/cpu/ doesn't exists."
		log_debug "Creating: Directory ${KITES_HOME}/cpu/"
		mkdir -p ${KITES_HOME}/cpu/
	fi
	cd ${KITES_HOME}/cpu/
	echo "$TEST_TYPE" >>cpu-$HOSTNAME-$CPU_TEST.txt
	echo "DATE, CPU-${HOSTNAME}" >>cpu-$HOSTNAME-$CPU_TEST.txt
	RUNTIME="$DURATION second"
	ENDTIME=$(date -ud "$RUNTIME" +%s)
	while [[ $(date -u +%s) -le $ENDTIME ]]; do
		DATE=$(date "+%Y-%m-%d %H:%M:%S")
		CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
		SINGLE_LINE="$DATE, $CPU_USAGE"
		echo $SINGLE_LINE >>cpu-$HOSTNAME-$CPU_TEST.txt
		#top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}' >> cpu-$HOSTNAME.txt
		sleep 1
	done
}
