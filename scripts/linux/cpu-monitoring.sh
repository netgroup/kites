#!/bin/bash

function start_cpu_monitor_nodes() {
	log_inf "Start CPU monitoring: $1 minions, type $4, cpu test $5"
	N=$1
	CONFIG=$2
	CONFIG_CODE=$3
	TEST_TYPE=$4
	CPU_TEST=$5
	BYTE=$6
	PPS=$7
	log_inf "Start CPU monitoring from master."
	if [ $PPS == "NO_POD" ]; then
		sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-master-1.k8s-play.local "${KITES_HOME}/scripts/linux/start-cpu-monitoring.sh \"$CONFIG\" $CONFIG_CODE \"$TEST_TYPE\" \"$CPU_TEST\" \"$BYTE\" $PPS" &
	else
		${KITES_HOME}/scripts/linux/start-cpu-monitoring.sh "$CONFIG" $CONFIG_CODE "$TEST_TYPE" $CPU_TEST $BYTE $PPS &
	fi
	log_inf "Start CPU monitoring from minions."
	for ((minion_n = 1; minion_n <= $N; minion_n++)); do
		sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-${minion_n}.k8s-play.local "${KITES_HOME}/scripts/linux/start-cpu-monitoring.sh \"$CONFIG\" $CONFIG_CODE \"$TEST_TYPE\" \"$CPU_TEST\" \"$BYTE\" $PPS" &
	done
}

function stop_cpu_monitor_nodes() {
	log_inf "Stop CPU monitoring"
	N=$1
	CONFIG=$2
	CONFIG_CODE=$3
	TEST_TYPE=$4
	CPU_TEST=$5
	BYTE=$6
	PPS=$7
	pid=$(cat ${KITES_HOME}/cpu/cpu-k8s-master-1-$CPU_TEST-${BYTE}-$CONFIG.pid)
	if [ $PPS = "NO_POD" ]; then
		kill_cmd=$(sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-master-1.k8s-play.local "kill $pid")
	else
		kill_cmd=$(kill $pid)
	fi
	if ($kill_cmd); then
		log_inf "Stopped CPU monitoring master"
		rm ${KITES_HOME}/cpu/cpu-k8s-master-1-$CPU_TEST-${BYTE}-$CONFIG.pid
	else
		log_error "CANNOT STOP CPU monitoring MASTER"
	fi

	for ((minion_n = 1; minion_n <= $N; minion_n++)); do
		pid=$(cat ${KITES_HOME}/cpu/cpu-k8s-minion-${minion_n}-$CPU_TEST-${BYTE}-$CONFIG.pid)
		if (sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-${minion_n}.k8s-play.local "kill $pid"); then
			log_inf "Stopped CPU monitoring minion$minion_n"
			rm ${KITES_HOME}/cpu/cpu-k8s-minion-${minion_n}-$CPU_TEST-${BYTE}-$CONFIG.pid
		else
			log_error "CANNOT STOP CPU monitoring MINION$minion_n"
		fi
	done
}

function start_cpu_monitor_node() {
	CONFIG=$1
	CONFIG_CODE=$2
	TEST_TYPE=$3
	CPU_TEST=$4
	BYTE=$5
	PPS=$6
	HOSTNAME=$(hostname)
	log_debug "Start CPU monitoring - node: $HOSTNAME - test type: $TEST_TYPE "
	if [ ! -d "${KITES_HOME}/cpu/" ]; then
		log_debug "Directory ${KITES_HOME}/cpu/ doesn't exists."
		log_debug "Creating: Directory ${KITES_HOME}/cpu/"
		mkdir -p "${KITES_HOME}/cpu/"
	fi

	echo $$ >"${KITES_HOME}/cpu/cpu-$HOSTNAME-$CPU_TEST-${BYTE}-$CONFIG.pid"

	cd "${KITES_HOME}/cpu/" || {
		log_error "Failure"
		exit 1
	}
	cpus=$(cat /proc/cpuinfo | grep processor | wc -l)
	for ((cpu_n=0; cpu_n<$cpus; cpu_n++)); do
		INPUT=CPU${cpu_n}-${HOSTNAME}
        cpusa[$cpu_n]=$INPUT
    done
    printf -v cpus_comma '%s,' "${cpusa[@]}"
	echo "PPS, CONFIG, CONFIG_CODE, TEST_TYPE, DATE, ${cpus_comma%,}, %" >>"cpu-$HOSTNAME-$CPU_TEST-${BYTE}bytes.csv"

	sleep 2
	while true; do
		DATE=$(date "+%Y-%m-%d %H:%M:%S")
		CPU_AVG=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
		CPU_USAGE=$(top 1 -bn1 | grep "Cpu" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' | sed -z 's/\n/,/g;s/,$/\n/')
		SINGLE_LINE="$PPS, $CONFIG, $CONFIG_CODE, $TEST_TYPE, $DATE, $CPU_AVG, $CPU_USAGE, %"
		echo "$SINGLE_LINE" >>"cpu-$HOSTNAME-$CPU_TEST-${BYTE}bytes.csv"
		#top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}' >> cpu-$HOSTNAME.txt
		sleep 1
	done

}
