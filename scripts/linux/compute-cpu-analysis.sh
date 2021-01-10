#!/bin/bash
calc() { awk "BEGIN{ printf \"%.2f\n\", $* }"; }
CPU_TEST=$1
CNI=$2
N=$3
shift 3
bytes=("$@")

cd /vagrant/ext/kites/cpu
sed -i -e "s/\r//g" *
IFS=','


for (( minion_n=1; minion_n<=$N; minion_n++ ))
    do
            INPUT=cpu-from-minion-${minion_n}
            minions[$minion_n]=$INPUT
done
printf -v minions_comma '%s,' "${minions[@]}"
for byte in "${bytes[@]}"
do
    echo "PPS, C, CONFIG, TEST_TYPE, cpu-from-master, ${minions_comma%,}" >"cpu-usage-${CNI}-${CPU_TEST}-${byte}bytes.csv"
done


for byte in "${bytes[@]}"
do
    files[0]=cpu-k8s-master-1-$CPU_TEST-${byte}bytes
    echo "pps, c, config, test_type, cpu_average" >"cpu_usage_${files[0]}.csv"
    for (( minion_n=1; minion_n<=$N; minion_n++ ))
    do
            INPUT=cpu-k8s-minion-${minion_n}-$CPU_TEST-${byte}bytes
            files[$minion_n]=$INPUT
            echo "pps, c, config, test_type, cpu_average" >"cpu_usage_${files[minion_n]}.csv"
            n=$((minion_n + 1))
            col=$((n * 5))
            columns[minion_n]=$col
    done
    printf -v columns_comma '%s,' "${columns[@]}"

    for i in "${!files[@]}"
    do
        for (( pps=17000; pps<=19000; pps+=200 ))
        do
            awk -F"," '$1=='$pps'' ${files[i]}.csv > temp_pps.csv
            configs_names=("SamePod" "SameNode" "DiffNode")
            for config in "${!configs_names[@]}"
            do
                echo "config= ${configs_names[$config]}"
                awk -F, '$3=='$config'' temp_pps.csv > temp${configs_names[$config]}.csv
                # awk -F, '$2=='$pps' && $3=='$config'' /vagrant/ext/kites/pod-shared/tests/${CNI}/udp_results_${CNI}_${byte}bytes.csv >> cpu_usage_${files[i]}.csv
                if ( [[ ${configs_names[$config]} == "SamePod" ]] || [[ ${configs_names[$config]} == "SameNode" ]]); then
                   
                    for (( minion_n=1; minion_n<=$N; minion_n++ ))
                    do
                        awk -F"," '$4 ~ /'k8s-minion-$minion_n'/' temp${configs_names[$config]}.csv > temp_minion.csv
                        if [ -s temp_minion.csv ]; then
                            cpu_avg=$(awk -F',' '{sum+=$6; ++n} END { print sum/n }' < temp_minion.csv)
                            echo "$pps, $config, ${configs_names[$config]}, k8s-minion-$minion_n, $cpu_avg" >> cpu_usage_${files[i]}.csv
                        fi
                    done
                elif [[ ${configs_names[$config]} == "DiffNode" ]]; then
                    for (( m_i=1; m_i<=$N; m_i++ ))
                    do
                        for (( m_j=1; m_j<=$N; m_j++ ))
                        do
                            if [ $m_j -ne $m_i ]; then
                                awk -F"," '$4 ~ /'k8s-minion-${m_i}TOk8s-minion-${m_j}'/' temp${configs_names[$config]}.csv > temp_minion.csv
                                count=$(awk -F',' 'BEGIN {n=0} $6==100 {n++} END {print n}' <temp_minion.csv)
                                total=$(awk -F',' '{n++} END {print n}' <temp_minion.csv)
                                percentage=$(calc 0.75*$total)
                                if [[ $count > $percentage ]]; then
                                    cpu_avg=100
                                else
                                    cpu_avg=$(awk -F',' '{sum+=$6; ++n} END { print sum/n }' < temp_minion.csv)
                                fi
                                echo "$pps, $config, ${configs_names[$config]}, k8s-minion-${m_i}TOk8s-minion-${m_j}, $cpu_avg" >> cpu_usage_${files[i]}.csv
                            fi
                        done
                    done
                fi
                cpu_file[i]=cpu_usage_${files[i]}.csv
                rm temp_minion.csv
                rm temp${configs_names[$config]}.csv
            done
            rm temp_pps.csv
        done

    done
    echo ${cpu_file[*]}
    paste -d, ${cpu_file[*]} | cut -d, -f 1,2,3,4,5,"${columns_comma%,}" >>cpu-usage-${CNI}-${CPU_TEST}-${byte}bytes.csv
    rm ${cpu_file[*]} 
done
