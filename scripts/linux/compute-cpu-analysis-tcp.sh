#!/bin/bash
calc() { awk "BEGIN{ printf \"%.2f\n\", $* }"; }
CPU_TEST=$1
CNI=$2
N=$3

cd /vagrant/ext/kites/cpu
sed -i -e "s/\r//g" *
IFS=','


files[0]=cpu-k8s-master-1-$CPU_TEST-nobytes
columns[0]=5
for (( minion_n=1; minion_n<=$N; minion_n++ ))
    do
            INPUT=cpu-from-minion-${minion_n}
            INPUT_CPU=cpu-k8s-minion-${minion_n}-$CPU_TEST-nobytes
            files[$minion_n]=$INPUT_CPU
            minions[$minion_n]=$INPUT
            n=$((minion_n - 1))
            col=$((columns[n] + 6))
            columns[minion_n]=$col
done
n1=$((N + 1))
columns[n1]=$((columns[N] + 1))
printf -v columns_comma '%s,' "${columns[@]}"
printf -v minions_comma '%s,' "${minions[@]}"
echo ${files[*]}

echo "TCP-CONFIG, C, CONFIG, TEST_TYPE, cpu-from-master, ${minions_comma%,}" >"cpu-usage-${CNI}-${CPU_TEST}.csv"

for i in "${!files[@]}"; do
    echo "tcp-config, c, config, test_type, cpu_avg, throughput" >>"cpu_usage_${files[i]}.csv"
    tcp_configs=("POD" "NO_POD")
    for tcp_config in "${!tcp_configs[@]}"; do
    echo ${tcp_configs[$tcp_config]}
        if [ ${tcp_configs[$tcp_config]} == "POD" ]; then
            awk -F"," '$6 !~ /'NO_POD'/' /vagrant/ext/kites/pod-shared/tests/${CNI}/iperf-tests.csv > temp_tcp_config.csv
        else 
            awk -F"," '$6 ~ /'NO_POD'/' /vagrant/ext/kites/pod-shared/tests/${CNI}/iperf-tests.csv > temp_tcp_config.csv
        fi
        configs_names=("SAMEPOD" "SAMENODE" "DIFFNODE")
        for config in "${!configs_names[@]}"
        do
            echo "config= ${configs_names[$config]}"
            awk -F, '$2 ~ /'${configs_names[$config]}'/' ${files[i]}.csv > temp_cpu_${configs_names[$config]}.csv
            #TO MODIFY
            tcp_thr=$(awk -F, '$19=='$config' { print $14 }' temp_tcp_config.csv)
            tcp_thr=number
            if ( [[ ${configs_names[$config]} == "SAMEPOD" ]] || [[ ${configs_names[$config]} == "SAMENODE" ]]); then
                for (( minion_n=1; minion_n<=$N; minion_n++ ))
                do
                    awk -F"," '$4 ~ /'k8s-minion-$minion_n'/' temp_cpu_${configs_names[$config]}.csv > temp_minion.csv
                    if [ -s temp_minion.csv ]; then
                        cpu_avg=$(awk -F',' '{sum+=$6; ++n} END { print sum/n }' < temp_minion.csv)
                        echo "${tcp_configs[$tcp_config]}, $config, ${configs_names[$config]}, k8s-minion-$minion_n, $cpu_avg, $tcp_thr" >> cpu_usage_${files[i]}.csv
                    fi
                done
            elif [[ ${configs_names[$config]} == "DIFFNODE" ]]; then
                for (( m_i=1; m_i<=$N; m_i++ ))
                do
                    for (( m_j=1; m_j<=$N; m_j++ ))
                    do
                        if [ $m_j -ne $m_i ]; then
                            awk -F"," '$4 ~ /'k8s-minion-${m_i}TOk8s-minion-${m_j}'/' temp_cpu_${configs_names[$config]}.csv > temp_minion.csv
                            count=$(awk -F',' 'BEGIN {n=0} $6==100 {n++} END {print n}' <temp_minion.csv)
                            total=$(awk -F',' '{n++} END {print n}' <temp_minion.csv)
                            percentage=$(calc 0.75*$total)
                            if [[ $count > $percentage ]]; then
                                cpu_avg=100
                            else
                                cpu_avg=$(awk -F',' '{sum+=$6; ++n} END { print sum/n }' < temp_minion.csv)
                            fi
                            echo "${tcp_configs[$tcp_config]}, $config, ${configs_names[$config]}, k8s-minion-${m_i}TOk8s-minion-${m_j}, $cpu_avg, $tcp_thr" >> cpu_usage_${files[i]}.csv
                        fi
                    done
                done
            fi
            cpu_file[i]=cpu_usage_${files[i]}.csv
            # rm temp_minion.csv
            # rm temp_cpu_${configs_names[$config]}.csv
        done
        # rm temp_tcp_config.csv
    done
done

echo ${cpu_file[*]}
paste -d, ${cpu_file[*]} | cut -d, -f 1,2,3,4,"${columns_comma%,}" >>cpu-usage-${CNI}-${CPU_TEST}.csv
# rm ${cpu_file[*]} 
