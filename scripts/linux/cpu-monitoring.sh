#!/bin/bash
sudo apt install -y sshpass
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-1.k8s-play.local "/vagrant/ext/kites/scripts/linux/start-cpu-monitoring.sh" |
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-2.k8s-play.local "/vagrant/ext/kites/scripts/linux/start-cpu-monitoring.sh" |
sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@k8s-minion-3.k8s-play.local "/vagrant/ext/kites/scripts/linux/start-cpu-monitoring.sh" 