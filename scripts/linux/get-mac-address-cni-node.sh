#!/bin/bash
cd /vagrant/ext/kites/pod-shared/ || {
    echo "No such directory"
    exit 1
}
/sbin/ip a show cni0 | grep "link/ether" | awk 'NR==1 { print $2}' >example.txt
sed -e "s/^/0x/g" example.txt >newfile.txt && sed -e "s/\:/, 0x/g" newfile.txt >address.txt && sed -e 's/$/,/g' address.txt >newAddress.txt
cat newAddress.txt
rm example.txt newfile.txt address.txt newAddress.txt
