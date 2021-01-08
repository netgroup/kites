#!/bin/bash
ID_EXP=$1
N=$2
BASE_FOLDER=/vagrant/ext/kites/pod-shared
RUN_TEST_SAME=$3
RUN_TEST_SAMENODE=$4
RUN_TEST_DIFF=$5
RUN_TEST_CPU=$6
CPU_TEST="TCP"
cd $BASE_FOLDER

for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
   declare n_plus=$((minion_n + 1))
   name_pod=$(awk 'NR=='$n_plus' { print $1}' podNameAndIP.txt)
   ip_pod=$(awk 'NR=='$n_plus' { print $2}' podNameAndIP.txt)
   host_pod=$(awk 'NR=='$n_plus' { print $3}' podNameAndIP.txt)
   declare -x "POD_NAME_$minion_n= $name_pod"
   declare -x "POD_IP_$minion_n= $ip_pod"
   declare -x "POD_HOSTNAME_$minion_n= $host_pod"
done
declare n_plus=$((N + 2))
SINGLE_POD_NAME=$(awk 'NR=='$n_plus' { print $1}' podNameAndIP.txt)
SINGLE_POD_IP=$(awk 'NR=='$n_plus' { print $2}' podNameAndIP.txt)
SINGLE_POD_HOSTNAME=$(awk 'NR=='$n_plus' { print $3}' podNameAndIP.txt)

for (( i=1; i<=$N; i++ ))
do
    echo -e "POD $i to other PODS...\n"
    echo -e "----------------------------------------------\n\n"
    for (( j=1; j<=$N; j++ ))
    do
        declare name1_pod="POD_NAME_$i"
        declare name2_pod="POD_NAME_$j"
        declare ip1_pod="POD_IP_$i"
        declare ip2_pod="POD_IP_$j"
        declare host1_pod="POD_HOSTNAME_$i"
        declare host2_pod="POD_HOSTNAME_$j"
        echo "host1_pod= ${!host1_pod}"
        echo "host2_pod= ${!host2_pod}"
        if [ "$i" -eq "$j" ] && $RUN_TEST_SAME; then
            if $RUN_TEST_CPU; then
                /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "SAMEPOD" 0 "${!host1_pod//[$' ']/}" $CPU_TEST "no" "no" "START" &
            fi
            kubectl exec -i ${!name1_pod} -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"${!ip1_pod}\" \"${!ip2_pod}\" \"${!host1_pod}\" \"${!host2_pod}\" \"${!name1_pod}\" \"${!name2_pod}\" $ID_EXP"
            if $RUN_TEST_CPU; then
                /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "SAMEPOD" 0 "${!host1_pod//[$' ']/}" $CPU_TEST "no" "no" "STOP"
            fi
        elif [ "${!host1_pod}" != "${!host2_pod}" ] &&  $RUN_TEST_DIFF; then
            if $RUN_TEST_CPU; then
                /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "DIFFNODE" 2 "${!host1_pod//[$' ']/}TO${!host2_pod//[$' ']/}" $CPU_TEST "no" "no" "START" &
            fi
            kubectl exec -i ${!name1_pod} -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"${!ip1_pod}\" \"${!ip2_pod}\" \"${!host1_pod}\" \"${!host2_pod}\" \"${!name1_pod}\" \"${!name2_pod}\" $ID_EXP"
            if $RUN_TEST_CPU; then
                /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "DIFFNODE" 2 "${!host1_pod//[$' ']/}TO${!host2_pod//[$' ']/}" $CPU_TEST "no" "no" "STOP"
            fi
        fi
    done
    if ( [ "${SINGLE_POD_HOSTNAME//[$' ']/}" = "${!host1_pod//[$' ']/}" ] && $RUN_TEST_SAMENODE ); then
        if $RUN_TEST_CPU; then
            /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "SAMENODE" 1 "${!host1_pod//[$' ']/}" $CPU_TEST "no" "no" "START" &
        fi
        kubectl exec -i ${!name1_pod} -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"${!ip1_pod}\" \"$SINGLE_POD_IP\" \"${!host1_pod}\" \"$SINGLE_POD_HOSTNAME\" \"${!name1_pod}\" \"$SINGLE_POD_NAME\" $ID_EXP"
        if $RUN_TEST_CPU; then
            /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "SAMENODE" 1 "${!host1_pod//[$' ']/}" $CPU_TEST "no" "no" "STOP"
        fi
    elif ( [ "${SINGLE_POD_HOSTNAME//[$' ']/}" != "${!host1_pod//[$' ']/}" ]  && $RUN_TEST_DIFF ); then
        if $RUN_TEST_CPU; then
            /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "DIFFNODE" 2 "${!host1_pod//[$' ']/}TO${SINGLE_POD_HOSTNAME//[$' ']/}" $CPU_TEST "no" "no" "START" &
        fi
        kubectl exec -i ${!name1_pod} -- bash -c "vagrant/ext/kites/scripts/linux/iperf-test.sh \"${!ip1_pod}\" \"$SINGLE_POD_IP\" \"${!host1_pod}\" \"$SINGLE_POD_HOSTNAME\" \"${!name1_pod}\" \"$SINGLE_POD_NAME\" $ID_EXP"
        if $RUN_TEST_CPU; then
            /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "DIFFNODE" 2 "${!host1_pod//[$' ']/}TO${SINGLE_POD_HOSTNAME//[$' ']/}" $CPU_TEST "no" "no" "STOP"
        fi
    fi
done
