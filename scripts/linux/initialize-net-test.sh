#!/bin/bash
CNI=$1
/vagrant/ext/kites/scripts/linux/initialize-pods.sh
/vagrant/ext/kites/scripts/linux/create-pods-list.sh
/vagrant/ext/kites/scripts/linux/create-udp-traffic.sh "$CNI"
