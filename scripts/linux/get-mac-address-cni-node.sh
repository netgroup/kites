#!/bin/bash

/sbin/ip a show cni0 | grep "link/ether" | awk 'NR==1 { print $2}'