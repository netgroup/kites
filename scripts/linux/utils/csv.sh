#!/bin/bash

function append_csv_from_iperf() {
    # CNI | Tipo di test | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Out Unit | Incoming | Inc Unit | Passed | Pass Unit | TX Time | RX Time
    CNI=$1
    TEST_TYPE=$2
    ID_EXP=$3
    VM_SRC=$4
    VM_DEST=$5
    POD_SRC=$6
    POD_DEST=$7
    IP_SRC=$8
    IP_DEST=$9
    OUTGOING=${10}
    OUT_UNIT=${11}
    INCOMING=${12}
    INC_UNIT=${13}
    THROUGHPUT=${14}
    THR_UNIT=${15}
    RX_TIME=${16}
    TX_TIME=${17}
    TIMESTAMP=${18}
    cd ${KITES_HOME}/pod-shared/tests/$CNI
    echo "$CNI, $TEST_TYPE, $ID_EXP, $VM_SRC, $VM_DEST, $POD_SRC, $POD_DEST, $IP_SRC, $IP_DEST, $OUTGOING, $OUT_UNIT, $INCOMING, $INC_UNIT, $THROUGHPUT, $THR_UNIT, $RX_TIME, $TX_TIME, $TIMESTAMP" >>iperf-tests.csv
}

function append_csv_from_netsniff() {
    CNI=$1
    TEST_TYPE=$2
    ID_EXP=$3
    PPS=$4
    VM_SRC=$5
    VM_DEST=$6
    POD_SRC=$7
    POD_DEST=$8
    IP_SRC=$9
    IP_DEST=${10}
    INCOMING=${11}
    PASSED=${12}
    RX_TIME=${13}
    TIMESTAMP=${14}
    BYTE=${15}
    CONFIG=${16}
    CONFIG_CODE=${17}
    OUTGOING=${18}
    TX_TIME=${19}
    cd ${KITES_HOME}/pod-shared/tests/$CNI
    echo "$CNI, $TEST_TYPE, $ID_EXP, $BYTE, $PPS, $VM_SRC, $VM_DEST, $POD_SRC, $POD_DEST, $IP_SRC, $IP_DEST, $OUTGOING ,$INCOMING, $PASSED, $TX_TIME ,$RX_TIME, $TIMESTAMP, $CONFIG, $CONFIG_CODE" >>netsniff-tests.csv
}

function append_csv_from_trafgen() {
    # CNI | Tipo di test | PPS | From VM | To VM | From Pod | To Pod | From IP | To IP | Outgoing | Incoming | Passed | TX Time | RX Time
    CNI=$1
    OUTGOING=$2
    TX_TIME=$3
    VM_SRC=$4
    VM_DEST=$5
    POD_SRC=$6
    POD_DEST=$7
    PPS=$8
    cd ${KITES_HOME}/pod-shared/tests/$CNI
    echo "$OUTGOING, $TX_TIME, $VM_SRC, $VM_DEST, $POD_SRC, $POD_DEST, $PPS" >>trafgen-tests.csv
}
