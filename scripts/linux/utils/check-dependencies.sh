#!/bin/bash

echo -n "Checking dependencies... \n"
for name in sshpass awk sshpass iperf3 jq; do
    [[ $(which $name 2>/dev/null) ]] || {
        echo -en "\n$name needs to be installed.  'sudo apt-get install $name' \n"
        deps=1
        sudo apt-get -y install $name
    }
done
# [[ $deps -ne 1 ]] && echo "OK" || {
#     echo -en "\nInstall the above and rerun this script\n"
#     exit 1
# }
