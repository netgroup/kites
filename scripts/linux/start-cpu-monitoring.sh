#!/bin/bash
HOSTNAME=$(hostname)
if [ -d "/vagrant/ext/kites/cpu/" ] 
then
    cd /vagrant/ext/kites/cpu/
else
    echo "Directory /vagrant/ext/kites/cpu/ doesn't exists."
    echo "Creating: Directory /vagrant/ext/kites/cpu/"
    mkdir -p /vagrant/ext/kites/cpu/ && cd /vagrant/ext/kites/cpu/
fi
echo "DATE, CPU-${HOSTNAME}" > cpu-$HOSTNAME.txt
RUNTIME="5 second"
ENDTIME=$(date -ud "$RUNTIME" +%s)
while [[ $(date -u +%s) -le $ENDTIME ]]
do 
	DATE=$(date "+%Y-%m-%d %H:%M:%S")
	CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
    SINGLE_LINE="$DATE, $CPU_USAGE"
	echo $SINGLE_LINE >> cpu-$HOSTNAME.txt
    #top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}' >> cpu-$HOSTNAME.txt
    sleep 1
done
