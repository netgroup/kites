#!/bin/bash
N=$1
CONFIG=$2
CONFIG_CODE=$3
TEST_TYPE=$4
CPU_TEST=$5
BYTE=$6
PPS=$7
STATUS=$8


if [ "$STATUS" == "START" ]; then
	/vagrant/ext/kites/scripts/linux/start-cpu-monitoring.sh "$CONFIG" $CONFIG_CODE "$TEST_TYPE" $CPU_TEST $BYTE $PPS &
else
	# pid=$(ps aux | grep start-cpu-monitoring.sh | awk 'NR==1 { print $2}')
	pid=$(cat /vagrant/ext/kites/cpu/cpu-k8s-master-1-$CPU_TEST-${BYTE}-$CONFIG.pid)
	if ( kill $pid ); then 
		echo "stopped master"; 
		rm /vagrant/ext/kites/cpu/cpu-k8s-master-1-$CPU_TEST-${BYTE}-$CONFIG.pid
	else 
		echo "CANNOT STOP MASTER"
	fi
fi
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
	if [ "$STATUS" == "START" ]; then
		sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-${minion_n}.k8s-play.local "/vagrant/ext/kites/scripts/linux/start-cpu-monitoring.sh \"$CONFIG\" $CONFIG_CODE \"$TEST_TYPE\" \"$CPU_TEST\" \"$BYTE\" $PPS" & 
	else
		pid=$(cat /vagrant/ext/kites/cpu/cpu-k8s-minion-${minion_n}-$CPU_TEST-${BYTE}-$CONFIG.pid)
		if ( sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-${minion_n}.k8s-play.local "kill $pid" ); then 
			echo "stopped minion$minion_n"; 
			rm /vagrant/ext/kites/cpu/cpu-k8s-minion-${minion_n}-$CPU_TEST-${BYTE}-$CONFIG.pid
		else 
			echo "CANNOT STOP MINION$minion_n"
		fi
	fi
done