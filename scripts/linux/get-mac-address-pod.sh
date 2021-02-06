#!/bin/bash

ip a show eth0 | grep "link/ether" | awk 'NR==1 { print $2}'
