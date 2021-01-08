#!/bin/bash

function kctl_exec() {
    log_debug "pod $1, namespace: ${KITES_NAMSPACE_NAME}, command: $2"
    kubectl -n "${KITES_NAMSPACE_NAME}" exec -i "$1" -- bash -c "$2"
}
