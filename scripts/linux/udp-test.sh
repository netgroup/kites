#!/bin/bash
N=$4
RUN_TEST_SAME=$5
RUN_TEST_SAMENODE=$6
RUN_TEST_DIFF=$7
RUN_TEST_CPU=$8
BASE_FOLDER=/vagrant/ext/kites/pod-shared
CPU_TEST="UDP"

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

for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
    folder_pod=pod$minion_n
    declare -x FOLDER_POD_$minion_n=$folder_pod
done

FOLDER_SINGLE_POD=single-pod
INTER_EXPERIMENT_SLEEP=3
PPS=$1
BYTE=$2
ID_EXP=$3
#echo -e "NETSNIFF TEST - ${BYTE}byte - ${PPS}pps\n" > NETSNIFF-${BYTE}byte-${PPS}pps.txt
#echo -e "TRAFGEN TEST - ${BYTE}byte - ${PPS}pps\n" > TRAFGEN-${BYTE}byte-${PPS}pps.txt

echo "Copy Pod-Shared on Root of the PODS"
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
    declare name1_pod="POD_NAME_$minion_n"
    kubectl exec -i ${!name1_pod} -- bash -c "/vagrant/ext/kites/scripts/linux/cp-pod-shared-to-root.sh"
done
if $RUN_TEST_SAMENODE; then
    kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/cp-pod-shared-to-root.sh"
fi


if $RUN_TEST_SAME || $RUN_TEST_DIFF; then
    for (( i=1; i<=$N; i++ ))
    do
        declare folder1p_name="FOLDER_POD_$i"
        cd $BASE_FOLDER/${!folder1p_name}

        echo -e "\n..................POD $i TEST..................\n"
        echo -e "----------------------------------------------\n\n"
        for (( j=1; j<=$N; j++ ))
        do
            declare name1_pod="POD_NAME_$i"
            declare name2_pod="POD_NAME_$j"
            declare ip1_pod="POD_IP_$i"
            declare ip2_pod="POD_IP_$j"
            declare host1_pod="POD_HOSTNAME_$i"
            declare host2_pod="POD_HOSTNAME_$j"
            declare folder2p_name="FOLDER_POD_$j"
            if [ "$i" -eq "$j" ] && $RUN_TEST_SAME; then
                if $RUN_TEST_CPU; then
                    /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "SAMEPOD: ${!name1_pod//[$' ']/}" 40 $CPU_TEST
                fi
                kubectl exec -i ${!name1_pod} -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh samePod$i-${BYTE}byte.pcap \"${!ip1_pod}\" \"${!ip1_pod}\" \"${!host1_pod}\" \"${!host1_pod}\" \"${!name1_pod}\" \"${!name1_pod}\" ${!folder1p_name} $BYTE $PPS $ID_EXP" & sleep 2 &&
                kubectl exec -i ${!name1_pod} -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh samePod$i-${BYTE}byte.cfg \"${!ip1_pod}\" \"${!ip1_pod}\" \"${!host1_pod}\" \"${!host1_pod}\" \"${!name1_pod}\" \"${!name1_pod}\" ${!folder1p_name} $BYTE $PPS"
            elif [ "${!host1_pod}" != "${!host2_pod}" ] &&  $RUN_TEST_DIFF; then
                echo "${!host1_pod} = ${!host2_pod}"
                if $RUN_TEST_CPU; then
                    /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "DIFFERENTNODES: ${!host1_pod//[$' ']/} TO ${!host2_pod//[$' ']/}" 40 $CPU_TEST
                fi
                kubectl exec -i ${!name1_pod} -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh pod${j}ToPod${i}-${BYTE}byte.pcap \"${!ip2_pod}\" \"${!ip1_pod}\" \"${!host2_pod}\" \"${!host1_pod}\" \"${!name2_pod}\" \"${!name1_pod}\" ${!folder1p_name} $BYTE $PPS $ID_EXP" & sleep 2 &&
                kubectl exec -i ${!name2_pod} -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh pod${j}ToPod${i}-${BYTE}byte.cfg \"${!ip2_pod}\" \"${!ip1_pod}\" \"${!host2_pod}\" \"${!host1_pod}\" \"${!name2_pod}\" \"${!name1_pod}\" ${!folder2p_name} $BYTE $PPS"
            fi
            sleep $INTER_EXPERIMENT_SLEEP
        done
    done
fi


if $RUN_TEST_SAMENODE; then
    echo -e "\n..................SINGLE POD TEST..................\n"
    echo -e "----------------------------------------------\n\n"

    if $RUN_TEST_SAME; then
        if $RUN_TEST_CPU; then
            /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "SAMEPOD: SINGLE" 40 $CPU_TEST
        fi
        kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh singlePodToSinglePod-${BYTE}byte.pcap \"$SINGLE_POD_IP\" \"$SINGLE_POD_IP\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_NAME\" \"$SINGLE_POD_NAME\" $FOLDER_SINGLE_POD $BYTE $PPS $ID_EXP" & sleep 2 &&
        kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh singlePodToSinglePod-${BYTE}byte.cfg \"$SINGLE_POD_IP\" \"$SINGLE_POD_IP\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_HOSTNAME\" \"$SINGLE_POD_NAME\" \"$SINGLE_POD_NAME\" $FOLDER_SINGLE_POD $BYTE $PPS"
        sleep $INTER_EXPERIMENT_SLEEP
    fi
    for (( minion_n=1; minion_n<=$N; minion_n++ ))
    do
        declare name1_pod="POD_NAME_$minion_n"
        declare ip1_pod="POD_IP_$minion_n"
        declare host1_pod="POD_HOSTNAME_$minion_n"
        declare folder1p_name="FOLDER_POD_$minion_n"
        echo "RUN_TEST_SAME: $RUN_TEST_SAMENODE and RUN_TEST_DIFF: $RUN_TEST_DIFF"
        echo "single: $SINGLE_POD_HOSTNAME and host1: ${!host1_pod}"
        if ( [ "${SINGLE_POD_HOSTNAME//[$' ']/}" = "${!host1_pod//[$' ']/}" ] && $RUN_TEST_SAMENODE ) || ( [ "${SINGLE_POD_HOSTNAME//[$' ']/}" != "${!host1_pod//[$' ']/}" ]  && $RUN_TEST_DIFF ); then
            echo "$SINGLE_POD_HOSTNAME = ${!host1_pod}"
            if $RUN_TEST_CPU; then
                /vagrant/ext/kites/scripts/linux/cpu-monitoring.sh $N "SINGLEPOD TO ${!name1_pod//[$' ']/}" 40 $CPU_TEST
            fi
            kubectl exec -i ${!name1_pod} -- bash -c "/vagrant/ext/kites/scripts/linux/netsniff-test.sh singlePodToPod$minion_n-${BYTE}byte.pcap \"$SINGLE_POD_IP\" \"${!ip1_pod}\" \"$SINGLE_POD_HOSTNAME\" \"${!host1_pod}\" \"$SINGLE_POD_NAME\" \"${!name1_pod}\" ${!folder1p_name} $BYTE $PPS $ID_EXP" & sleep 2 &&
            kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/trafgen-test.sh singlePodToPod$minion_n-${BYTE}byte.cfg \"$SINGLE_POD_IP\" \"${!ip1_pod}\" \"$SINGLE_POD_HOSTNAME\" \"${!host1_pod}\" \"$SINGLE_POD_NAME\" \"${!name1_pod}\" $FOLDER_SINGLE_POD $BYTE $PPS"
            sleep $INTER_EXPERIMENT_SLEEP
        fi
    done
fi

echo -e "\nCopy Root on Pod-Shared\n"
for (( minion_n=1; minion_n<=$N; minion_n++ ))
do
    declare name1_pod="POD_NAME_$minion_n"
    kubectl exec -i ${!name1_pod} -- bash -c "/vagrant/ext/kites/scripts/linux/cp-root-to-pod-shared.sh"
done
if $RUN_TEST_SAMENODE; then
    kubectl exec -i $SINGLE_POD_NAME -- bash -c "/vagrant/ext/kites/scripts/linux/cp-root-to-pod-shared.sh"
fi
