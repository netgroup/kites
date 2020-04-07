#!/bin/sh
HOSTNAME=$(hostname)
/sbin/ip a | grep "eth1" | grep "inet" | awk 'NR==1 { print $2}' > example.txt
IP_HOSTNAME=$(sed -e 's/.\{3\}$//' example.txt)
echo $IP_HOSTNAME
#Install package if not installed
sudo yum install -y iperf3 
#Start Iperf3 TCP Test
BASE_FOLDER=/vagrant/ext/kites/pod-shared
cd $BASE_FOLDER
POD_NAME_1=$(awk 'NR==2 { print $1}' podNameAndIP.txt)
POD_NAME_2=$(awk 'NR==3 { print $1}' podNameAndIP.txt)
POD_NAME_3=$(awk 'NR==4 { print $1}' podNameAndIP.txt)
POD_IP_1=$(awk 'NR==2 { print $2}' podNameAndIP.txt)
POD_IP_2=$(awk 'NR==3 { print $2}' podNameAndIP.txt)
POD_IP_3=$(awk 'NR==4 { print $2}' podNameAndIP.txt)
POD_HOSTNAME_1=$(awk 'NR==2 { print $3}' podNameAndIP.txt)
POD_HOSTNAME_2=$(awk 'NR==3 { print $3}' podNameAndIP.txt)
POD_HOSTNAME_3=$(awk 'NR==4 { print $3}' podNameAndIP.txt)
SINGLE_POD_NAME=$(awk 'NR==5 { print $1}' podNameAndIP.txt)
SINGLE_POD_IP=$(awk 'NR==5 { print $2}' podNameAndIP.txt)
SINGLE_POD_HOSTNAME=$(awk 'NR==5 { print $3}' podNameAndIP.txt)
SINGLE_POD_IP=$(awk 'NR==5 { print $2}' podNameAndIP.txt)
echo -e "$HOSTNAME to other PODS...\n"
echo -e "----------------------------------------------\n\n"
/vagrant/ext/kites/scripts/linux/iperf-test-node.sh \"$IP_HOSTNAME\" \"$POD_IP_1\" \"$HOSTNAME\" \"$POD_HOSTNAME_1\" "NO_POD" \"$POD_NAME_1\"
/vagrant/ext/kites/scripts/linux/iperf-test-node.sh \"$IP_HOSTNAME\" \"$POD_IP_2\" \"$HOSTNAME\" \"$POD_HOSTNAME_2\" "NO_POD" \"$POD_NAME_2\"
/vagrant/ext/kites/scripts/linux/iperf-test-node.sh \"$IP_HOSTNAME\" \"$POD_IP_3\" \"$HOSTNAME\" \"$POD_HOSTNAME_3\" "NO_POD" \"$POD_NAME_3\"
/vagrant/ext/kites/scripts/linux/iperf-test-node.sh \"$IP_HOSTNAME\" \"$SINGLE_POD_IP\" \"$HOSTNAME\" \"$SINGLE_POD_HOSTNAME\" "NO_POD" \"$SINGLE_POD_NAME\"
exit