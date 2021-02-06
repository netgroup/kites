#!/bin/bash
. logging.sh

function create_udp_traffic() {
    CNI=$1
    N=$2
    RUN_TEST_SAME=$3
    RUN_TEST_SAMENODE=$4
    RUN_TEST_DIFF=$5
    V=$6
    shift 6
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
            export POD_IP_$minion_n MAC_ADDR_POD_$minion_n MAC_ADDR_MINION_$minion_n
        done
        for byte in "${bytes[@]}"; do
            log_debug "Creating UDP packets with size: $byte bytes"
            for ((i = 1; i <= $N; i++)); do
                for ((j = 1; j <= $N; j++)); do
                    if [ "$V" == "4" ]; then
                        declare ip1_name="POD_IP_$i"
                        declare ip2_name="POD_IP_$j"
                    elif [ "$V" == "6" ]; then
                        declare ip1_name="POD_IP6_$i"
                        declare ip2_name="POD_IP6_$j"
                    fi
                    declare mac1_pod="MAC_ADDR_POD_$i"
                    declare mac2_pod="MAC_ADDR_POD_$j"
                    declare mac1_minion="MAC_ADDR_MINION_$i"
                    declare mac2_minion="MAC_ADDR_MINION_$j"
                    if [ "$i" -eq "$j" ]; then
                        create_udp_packet "${!mac1_pod}" "${!mac1_pod}" "${!ip1_name}" "${!ip2_name}" $byte samePod$i pod$i $CNI $V
                    else
                        create_udp_packet "${!mac1_pod}" "${!mac1_minion}" "${!ip1_name}" "${!ip2_name}" $byte pod${i}ToPod${j} pod$i $CNI $V
                        create_udp_packet "${!mac2_pod}" "${!mac2_minion}" "${!ip2_name}" "${!ip1_name}" $byte pod${j}ToPod${i} pod$i $CNI $V
                    fi
                done
            done
        done
        log_debug "Creating UDP Packets for Single Pod..."
        if $RUN_TEST_SAMENODE; then
            create_udp_traffic_single_pod_flannel $CNI $N $V "${bytes[@]}"
        fi
    else
        log_debug "Creating UDP Packet for DaemonSet... IPv$V"
        for ((minion_n = 1; minion_n <= $N; minion_n++)); do
            export POD_IP_$minion_n MAC_ADDR_POD_$minion_n POD_HOSTNAME_$minion_n
        done
        for byte in "${bytes[@]}"; do
            log_debug "Creating UDP packets with size: $byte bytes"
            for ((i = 1; i <= $N; i++)); do
                for ((j = 1; j <= $N; j++)); do
                    if [ "$V" == "4" ]; then
                        declare ip1_name="POD_IP_$i"
                        declare ip2_name="POD_IP_$j"
                    elif [ "$V" == "6" ]; then
                        declare ip1_name="POD_IP6_$i"
                        declare ip2_name="POD_IP6_$j"
                    fi
                    declare mac1_pod="MAC_ADDR_POD_$i"
                    declare mac2_pod="MAC_ADDR_POD_$j"
                    declare name_vm1="POD_HOSTNAME_$i"
                    declare name_vm2="POD_HOSTNAME_$j"
                    if [ "$i" -eq "$j" ] && $RUN_TEST_SAME; then
                        #log_debug "Same pods $i - $j --- ${!ip1_name}-${!ip2_name}"
                        create_udp_packet "${!mac1_pod}" "${!mac1_pod}" "${!ip1_name}" "${!ip2_name}" $byte samePod$i pod$i $CNI $V
                    elif [ "${!name_vm1}" != "${!name_vm2}" ] && $RUN_TEST_DIFF; then
                        #log_debug "diff nodes $i - $j --- ${!ip1_name}-${!ip2_name}"
                        create_udp_packet "${!mac1_pod}" "${!mac2_pod}" "${!ip1_name}" "${!ip2_name}" $byte pod${i}ToPod${j} pod$i $CNI $V
                        create_udp_packet "${!mac2_pod}" "${!mac1_pod}" "${!ip2_name}" "${!ip1_name}" $byte pod${j}ToPod${i} pod$i $CNI $V
                    fi
                done
            done
        done
        if $RUN_TEST_SAMENODE; then
            #log_debug "same node"
            create_udp_traffic_single_pod "$CNI" "$N" "$RUN_TEST_SAME" "$RUN_TEST_SAMENODE" "$RUN_TEST_DIFF" "$V" "${bytes[@]}"
        fi
    fi
}

function create_udp_traffic_single_pod_flannel() {
    CNI=$1
    N=$2
    V=$3
    shift 3
    bytes=("$@")

    log_debug "Creating UDP Packets for single POD"
    for ((minion_n = 1; minion_n <= $N; minion_n++)); do
        declare n_plus=$((minion_n + 1))
        host_pod=$(awk 'NR=='$n_plus' { print $3}' podNameAndIP.txt)
        declare -x "MINION_$minion_n= $host_pod"
    done
    MINION_SINGLE_POD=$(awk 'NR=='$((N + 2))' { print $3}' podNameAndIP.txt)

    if [ "$V" == "4" ]; then
        declare s_pod_ip="SINGLE_POD_IP"
    elif [ "$V" == "6" ]; then
        declare s_pod_ip="SINGLE_POD_IP6"
    fi

    for ((minion_n = 1; minion_n <= $N; minion_n++)); do
        declare hostname="MINION_$minion_n"
        if [ "${!hostname//[$' ']/}" = "$MINION_SINGLE_POD" ]; then
            # bytes=(100 1000)
            for byte in "${bytes[@]}"; do
                log_debug "Creating UDP packets with size: $byte bytes"
                create_udp_packet "$MAC_ADDR_SINGLE_POD" "$MAC_ADDR_SINGLE_POD" "${!s_pod_ip}" "${!s_pod_ip}" $byte singlePodToSinglePod single-pod $CNI $V
                for ((j = 1; j <= $N; j++)); do
                    declare mac_addr_pod="MAC_ADDR_POD_$minion_n"
                    declare mac_addr_minion="MAC_ADDR_MINION_$minion_n"
                    if [ "$V" == "4" ]; then
                        declare ip_pod="POD_IP_$i"
                    elif [ "$V" == "6" ]; then
                        declare ip_pod="POD_IP6_$i"
                    fi
                    if [ $minion_n -eq $j ]; then
                        create_udp_packet "$MAC_ADDR_SINGLE_POD" "${!mac_addr_pod}" "${!s_pod_ip}" "${!ip_pod}" $byte singlePodToPod$j single-pod $CNI $V
                        create_udp_packet "$MAC_ADDR_SINGLE_POD" "${!mac_addr_pod}" "${!s_pod_ip}" "${!ip_pod}" $byte singlePodToPod$j pod$j $CNI $V
                    else
                        create_udp_packet "$MAC_ADDR_SINGLE_POD" "${!mac_addr_minion}" "${!s_pod_ip}" "${!ip_pod}" $byte singlePodToPod$j single-pod $CNI $V
                        create_udp_packet "$MAC_ADDR_SINGLE_POD" "${!mac_addr_minion}" "${!s_pod_ip}" "${!ip_pod}" $byte singlePodToPod$j pod$j $CNI $V
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
    V=$6
    shift 6
    bytes=("$@")

    log_debug "Creating UDP Packets for single POD"

    if [ "$V" == "4" ]; then
        declare s_pod_ip="SINGLE_POD_IP"
    elif [ "$V" == "6" ]; then
        declare s_pod_ip="SINGLE_POD_IP6"
    fi

    if $RUN_TEST_SAME; then
        for byte in "${bytes[@]}"; do
            create_udp_packet "$MAC_ADDR_SINGLE_POD" "$MAC_ADDR_SINGLE_POD" "${!s_pod_ip}" "${!s_pod_ip}" "$byte" "singlePodToSinglePod" "single-pod" "$CNI" "$V"
        done
    fi

    for byte in "${bytes[@]}"; do
        for ((i = 1; i <= $N; i++)); do
            if [ "$V" == "4" ]; then
                declare ip1_name="POD_IP_$i"
            elif [ "$V" == "6" ]; then
                declare ip1_name="POD_IP6_$i"
            fi
            declare mac_pod="MAC_ADDR_POD_$i"
            declare name_vm1="POD_HOSTNAME_$i"
            #log_debug "nomehost ${!name_vm1} e nome single pod $SINGLE_POD_HOSTNAME ed vero? $RUN_TEST_DIFF"
            if ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" = "${!name_vm1//[$' ']/}" ] && $RUN_TEST_SAMENODE) || ([ "${SINGLE_POD_HOSTNAME//[$' ']/}" != "${!name_vm1//[$' ']/}" ] && $RUN_TEST_DIFF); then
                create_udp_packet "$MAC_ADDR_SINGLE_POD" "${!mac_pod}" "${!s_pod_ip}" "${!ip1_name}" $byte singlePodToPod$i single-pod $CNI $V
                create_udp_packet "$MAC_ADDR_SINGLE_POD" "${!mac_pod}" "${!s_pod_ip}" "${!ip1_name}" $byte singlePodToPod$i pod$i $CNI $V
            fi
        done
    done
}

function create_udp_packet() {
    MAC_ADDR_POD_SRC=$1
    MAC_ADDR_POD_DST=$2
    IP_ADDR_SRC=$3
    IP_ADDR_DST=$4
    BYTE=$5
    BYTE_FILENAME=$5
    FILENAME=$6
    FOLDER=$7
    CNI=$8
    V=$9
    BASE_FOLDER="${KITES_HOME}/pod-shared"

    log_debug "create UDP pack $IP_ADDR_SRC - $IP_ADDR_DST - $9"

    MAC_SRC=$(sed -e "s/\"//g" <<<$MAC_ADDR_POD_SRC)
    if [ "$CNI" == "calicoIPIP" ] || [ "$CNI" == "calicoVXLAN" ]; then
        MAC_DST="0xee, 0xee, 0xee, 0xee, 0xee, 0xee,"
    else
        MAC_DST=$(sed -e "s/\"//g" <<<$MAC_ADDR_POD_DST)
        MAC_DST=$(sed -e "s/^ *//g" <<<$MAC_DST)
    fi

    if [ ! -d "${BASE_FOLDER}/${FOLDER}" ]; then
        log_debug "Directory ${BASE_FOLDER}/${FOLDER} doesn't exists."
        log_debug "Creating: Directory ${BASE_FOLDER}/${FOLDER}"
        mkdir -p "${BASE_FOLDER}/${FOLDER}"
    fi

    cd "${BASE_FOLDER}/${FOLDER}" || {
        log_error "Failure"
        exit 1
    }

    if [ "$V" == "4" ]; then
        create_udp_packet_IPv4 "$MAC_SRC" "$MAC_DST" "$IP_ADDR_SRC" "$IP_ADDR_DST" "$BYTE" "${FILENAME}-${BYTE_FILENAME}byte"
    elif [ "$V" == "6" ]; then
        create_udp_packet_IPv6 "$MAC_SRC" "$MAC_DST" "$IP_ADDR_SRC" "$IP_ADDR_DST" "$BYTE" "${FILENAME}-${BYTE_FILENAME}byte"
    fi

}

function create_udp_packet_IPv4() {
    log_debug "create UDP packet IPv4"

    MAC_ADDR_SRC=$1
    MAC_ADDR_DST=$2
    IP_ADDR_SRC=$3
    IP_ADDR_DST=$4
    BYTE=$5
    FILE_NAME=$6
    IP_ADDR_SRC=$(sed -e "s/\./, /g" <<<${IP_ADDR_SRC})
    IP_ADDR_DST=$(sed -e "s/\./, /g" <<<${IP_ADDR_DST})
    IP_ADDR_SRC=$(sed -e "s/[\"\r]//g" <<<$IP_ADDR_SRC)
    IP_ADDR_DST=$(sed -e "s/[\"\r]//g" <<<$IP_ADDR_DST)

    PAYLOAD=$((BYTE - 42))
    UDP_LEN=$((PAYLOAD + 8))
    IP_LEN=$((UDP_LEN + 20))

    echo -n "{
    ${MAC_ADDR_DST}
    ${MAC_ADDR_SRC}
    0x08, 0x00,
    0b01000101, 0,
    const16($IP_LEN),
    const16(2),
    0b01000000, 0,
    64,
    17,
    csumip(14, 33),
    ${IP_ADDR_SRC},
    ${IP_ADDR_DST},
    const16(9),
    const16(6666),
    const16($UDP_LEN),
    const16(0),
    fill('B', $PAYLOAD),
    }" >${FILE_NAME}.cfg
}

function create_udp_packet_IPv6() {
    log_debug "create UDP packet IPv4"
    MAC_ADDR_SRC=$1
    MAC_ADDR_DST=$2
    IP_ADDR_SRC=$3
    IP_ADDR_DST=$4
    BYTE=$5
    FILE_NAME=$6

    PAYLOAD=$((BYTE - 62))
    UDP_LEN=$((PAYLOAD + 8))

    # get Expanded IPv6 Address
    IP_ADDR_SRC=$(sipcalc $IP_ADDR_SRC | fgrep Expanded | cut -d '-' -f 2 | sed -e "s/^\s//g" | sed -e "s/\://g" | sed -e "s/../, 0x&/g")
    IP_ADDR_SRC=$(sed -e "s/^\,\s//g" <<<${IP_ADDR_SRC})
    #IP_ADDR_SRC=$(sed -e "s/../ ,0x&/g" <<<${IP_ADDR_SRC})
    IP_ADDR_DST=$(sipcalc $IP_ADDR_DST | fgrep Expanded | cut -d '-' -f 2 | sed -e "s/^\s//g" | sed -e "s/\://g" | sed -e "s/../, 0x&/g")
    IP_ADDR_DST=$(sed -e "s/^\,\s//g" <<<${IP_ADDR_DST})
    #IP_ADDR_DST=$(sed -e "s/../ ,0x&/g" <<<${IP_ADDR_DST})
    log_debug "$IP_ADDR_SRC"
    log_debug "$IP_ADDR_DST"

    echo -n "{
    ${MAC_ADDR_DST}
    ${MAC_ADDR_SRC}
    0x86, 0xdd,
    0x60, 0x0b, 0x1d, 0x04,
    const16($UDP_LEN),
    17,
    64,
    $IP_ADDR_SRC,
    $IP_ADDR_DST,
    const16(56548),
    const16(6666),
    const16($UDP_LEN),
    csumip(14, 53),
    fill('B', $PAYLOAD),
    }" >${FILE_NAME}.cfg
}
