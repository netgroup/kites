#!/bin/bash
iptables -A INPUT -p 17 -m udp --dport 6666 -j DROP

iperf3 -s