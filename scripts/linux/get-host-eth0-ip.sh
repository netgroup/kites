#!/bin/bash
/sbin/ip a show eth0 | grep 'inet' | awk 'NR==1 { print $2}' | sed 's/.\{3\}$//'
