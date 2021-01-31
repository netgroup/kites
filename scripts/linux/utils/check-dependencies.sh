#!/bin/bash

log_debug "Checking dependencies... "
for name in sshpass awk sshpass iperf3 jq sipcalc; do
    [[ $(which $name 2>/dev/null) ]] || {
        log_debug "$name needs to be installed.  'sudo apt-get install $name' "
        sudo apt-get -y install $name
    }
done
# [[ $deps -ne 1 ]] && echo "OK" || {
#     echo -en "\nInstall the above and rerun this script\n"
#     exit 1
# }
