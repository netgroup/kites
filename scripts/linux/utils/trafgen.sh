#!/bin/bash
. logging.sh

function create_udp_traffic_ipv4() {
    CNI=$1
    N=$2
    RUN_TEST_SAME=$3
    RUN_TEST_SAMENODE=$4
    RUN_TEST_DIFF=$5
    shift 5
    bytes=("$@")

    if [ "$CNI" == "flannel" ]; then
        log_debug "Obtaining MAC Addresses of the Nodes for $CNI..."

        for ((minion_n = 1; minion_n <= $N; minion_n++)); do
            declare minion="POD_HOSTNAME_$minion_n"
            # MUST FIX THIS
            min_mac=$(sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@${!minion//[$' ']/}.k8s-play.local "/vagrant/ext/kites/scripts/linux/get-mac-address-cni-node.sh")
            declare -x "MAC_ADDR_MINION_$minion_n=$min_mac"
        done
        log_debug "Creating UDP Packet for DaemonSet..."
        for ((minion_n = 1; minion_n <= $N; minion_n++)); do
            export IP_$minion_n MAC_ADDR_POD_$minion_n MAC_ADDR_MINION_$minion_n
        done
        for byte in "${bytes[@]}"; do
            log_debug "Creating UDP packets with size: $byte bytes"
            for ((i = 1; i <= $N; i++)); do
                for ((j = 1; j <= $N; j++)); do
                    declare ip1_name="IP_$i"
                    declare ip2_name="IP_$j"
                    declare mac1_pod="MAC_ADDR_POD_$i"
                    declare mac2_pod="MAC_ADDR_POD_$j"
                    declare mac1_minion="MAC_ADDR_MINION_$i"
                    declare mac2_minion="MAC_ADDR_MINION_$j"
                    if [ "$i" -eq "$j" ]; then
                        create_udp_packet_ipv4 "${!mac1_pod}" "${!mac1_pod}" "${!ip1_name}" "${!ip2_name}" $byte samePod$i pod$i $CNI
                    else
                        create_udp_packet_ipv4 "${!mac1_pod}" "${!mac1_minion}" "${!ip1_name}" "${!ip2_name}" $byte pod${i}ToPod${j} pod$i $CNI
                        create_udp_packet_ipv4 "${!mac2_pod}" "${!mac2_minion}" "${!ip2_name}" "${!ip1_name}" $byte pod${j}ToPod${i} pod$i $CNI
                    fi
                done
            done
        done
        log_debug "Creating UDP Packets for Single Pod..."
        if $RUN_TEST_SAMENODE; then
            create_udp_traffic_single_pod_flannel $CNI $N "${bytes[@]}"
        fi
    else
        log_debug "Creating UDP Packet for DaemonSet..."
        for ((minion_n = 1; minion_n <= $N; minion_n++)); do
            export IP_$minion_n MAC_ADDR_POD_$minion_n POD_HOSTNAME_$minion_n
        done
        for byte in "${bytes[@]}"; do
            log_debug "Creating UDP packets with size: $byte bytes"
            for ((i = 1; i <= $N; i++)); do
                for ((j = 1; j <= $N; j++)); do
                    declare ip1_name="IP_$i"
                    declare ip2_name="IP_$j"
                    declare mac1_pod="MAC_ADDR_POD_$i"
                    declare mac2_pod="MAC_ADDR_POD_$j"
                    declare name_vm1="POD_HOSTNAME_$i"
                    declare name_vm2="POD_HOSTNAME_$j"
                    if [ "$i" -eq "$j" ] && $RUN_TEST_SAME; then
                        #log_debug "Same pods"
                        create_udp_packet_ipv4 "${!mac1_pod}" "${!mac1_pod}" "${!ip1_name}" "${!ip2_name}" $byte samePod$i pod$i $CNI
                    elif [ "${!name_vm1}" != "${!name_vm2}" ] && $RUN_TEST_DIFF; then
                        #log_debug "diff nodes"
                        create_udp_packet_ipv4 "${!mac1_pod}" "${!mac2_pod}" "${!ip1_name}" "${!ip2_name}" $byte pod${i}ToPod${j} pod$i $CNI
                        create_udp_packet_ipv4 "${!mac2_pod}" "${!mac1_pod}" "${!ip2_name}" "${!ip1_name}" $byte pod${j}ToPod${i} pod$i $CNI
                    fi
                done
            done
        done
        if $RUN_TEST_SAMENODE; then
            create_udp_traffic_single_pod "$CNI" "$N" "$RUN_TEST_SAME" "$RUN_TEST_SAMENODE" "$RUN_TEST_DIFF" "${bytes[@]}"
        fi
    fi
}

function create_udp_traffic_single_pod_flannel() {
    CNI=$1
    N=$2
    shift 2
    bytes=("$@")

    log_debug "Creating UDP Packets for single POD"
    for ((minion_n = 1; minion_n <= $N; minion_n++)); do
        declare n_plus=$((minion_n + 1))
        host_pod=$(awk 'NR=='$n_plus' { print $3}' podNameAndIP.txt)
        declare -x "MINION_$minion_n= $host_pod"
    done
    MINION_SINGLE_POD=$(awk 'NR=='$((N + 2))' { print $3}' podNameAndIP.txt)

    for ((minion_n = 1; minion_n <= $N; minion_n++)); do
        declare hostname="MINION_$minion_n"
        if [ "${!hostname//[$' ']/}" = "$MINION_SINGLE_POD" ]; then
            # bytes=(100 1000)
            for byte in "${bytes[@]}"; do
                log_debug "Creating UDP packets with size: $byte bytes"
                create_udp_packet_ipv4 "$MAC_ADDR_SINGLE_POD" "$MAC_ADDR_SINGLE_POD" "$IP_PARSED_SINGLE_POD" "$IP_PARSED_SINGLE_POD" $byte singlePodToSinglePod single-pod $CNI
                for ((j = 1; j <= $N; j++)); do
                    declare mac_addr_pod="MAC_ADDR_POD_$minion_n"
                    declare mac_addr_minion="MAC_ADDR_MINION_$minion_n"
                    declare ip_pod="IP_$j"
                    if [ $minion_n -eq $j ]; then
                        create_udp_packet_ipv4 "$MAC_ADDR_SINGLE_POD" "${!mac_addr_pod}" "$IP_PARSED_SINGLE_POD" "${!ip_pod}" $byte singlePodToPod$j single-pod $CNI
                        create_udp_packet_ipv4 "$MAC_ADDR_SINGLE_POD" "${!mac_addr_pod}" "$IP_PARSED_SINGLE_POD" "${!ip_pod}" $byte singlePodToPod$j pod$j $CNI
                    else
                        create_udp_packet_ipv4 "$MAC_ADDR_SINGLE_POD" "${!mac_addr_minion}" "$IP_PARSED_SINGLE_POD" "${!ip_pod}" $byte singlePodToPod$j single-pod $CNI
                        create_udp_packet_ipv4 "$MAC_ADDR_SINGLE_POD" "${!mac_addr_minion}" "$IP_PARSED_SINGLE_POD" "${!ip_pod}" $byte singlePodToPod$j pod$j $CNI
                    fi
                done
            done
        fi
    done
}

function create_udp_traffic_single_pod() {
    CNI=$1
    N=$2
    RUN_TEST_SAME=$3
    RUN_TEST_SAMENODE=$4
    RUN_TEST_DIFF=$5
    shift 5
    bytes=("$@")

    log_debug "Creating UDP Packets for single POD"
    if $RUN_TEST_SAME; then
        for byte in "${bytes[@]}"; do
            create_udp_packet_ipv4 "$MAC_ADDR_SINGLE_POD" "$MAC_ADDR_SINGLE_POD" "$IP_PARSED_SINGLE_POD" "$IP_PARSED_SINGLE_POD" $byte singlePodToSinglePod single-pod $CNI
        done
    fi

    for byte in "${bytes[@]}"; do
        for ((i = 1; i <= $N; i++)); do
            declare ip1_name="IP_$i"
            declare mac_pod="MAC_ADDR_POD_$i"
            declare name_vm1="POD_HOSTNAME_$i"
            #log_debug "nomehost ${!name_vm1} e nome single pod $SINGLE_POD_HOSTNAME ed vero? $RUN_TEST_DIFF"
            if ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" = "${!name_vm1//[$' ']/}" ] && $RUN_TEST_SAMENODE) || ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" != "${!name_vm1//[$' ']/}" ] && $RUN_TEST_DIFF); then
                #log_debug "$SINGLE_POD_HOSTNAME = ${!name_vm1}"
                create_udp_packet_ipv4 "$MAC_ADDR_SINGLE_POD" "${!mac_pod}" "$IP_PARSED_SINGLE_POD" "${!ip1_name}" $byte singlePodToPod$i single-pod $CNI
                create_udp_packet_ipv4 "$MAC_ADDR_SINGLE_POD" "${!mac_pod}" "$IP_PARSED_SINGLE_POD" "${!ip1_name}" $byte singlePodToPod$i pod$i $CNI
            fi
        done
    done
}

function create_udp_packet_ipv4() {
    MAC_ADDR_POD_SRC=$1
    MAC_ADDR_POD_DST=$2
    IP_ADDR_POD_1=$3
    IP_ADDR_POD_2=$4
    BYTE=$5
    BYTE_FILENAME=$5
    FILENAME=$6
    FOLDER=$7
    CNI=$8
    BASE_FOLDER="${KITES_HOME}/pod-shared"

    log_debug "create UDP pack $IP_ADDR_POD_1 $IP_ADDR_POD_2"

    NEW_MAC_ADDR_POD_SRC=$(sed -e "s/\"//g" <<<$MAC_ADDR_POD_SRC)
    if [ "$CNI" == "calicoIPIP" ] || [ "$CNI" == "calicoVXLAN" ]; then
        NEW_MAC_ADDR_POD_DST="0xee, 0xee, 0xee, 0xee, 0xee, 0xee,"
    else
        NEW_MAC_ADDR_POD_DST=$(sed -e "s/\"//g" <<<$MAC_ADDR_POD_DST)
        NEW_MAC_ADDR_POD_DST=$(sed -e "s/^ *//g" <<<$NEW_MAC_ADDR_POD_DST)
    fi

    NEW_IP_ADDR_POD_1=$(sed -e "s/[\"\r]//g" <<<$IP_ADDR_POD_1)
    NEW_IP_ADDR_POD_2=$(sed -e "s/[\"\r]//g" <<<$IP_ADDR_POD_2)

    if [ ! -d "${BASE_FOLDER}/${FOLDER}" ]; then
        log_debug "Directory ${BASE_FOLDER}/${FOLDER} doesn't exists."
        log_debug "Creating: Directory ${BASE_FOLDER}/${FOLDER}"
        mkdir -p "${BASE_FOLDER}/${FOLDER}"
    fi

    cd "${BASE_FOLDER}/${FOLDER}" || {
        log_error "Failure"
        exit 1
    }

    echo -n "{
    ${NEW_MAC_ADDR_POD_DST}
    ${NEW_MAC_ADDR_POD_SRC}
    0x08, 0x00,
    0b01000101, 0,
    const16(46),
    const16(2),
    0b01000000, 0,
    64,
    17,
    csumip(14, 33),
    ${NEW_IP_ADDR_POD_1},
    ${NEW_IP_ADDR_POD_2},
    const16(9),
    const16(6666),
    const16(26),
    const16(0),
    fill('B', $((BYTE - 42))),
    }" >${FILENAME}-${BYTE_FILENAME}byte.cfg
}
