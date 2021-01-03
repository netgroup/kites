#!/bin/bash
IP_ADDR_SINGLE_POD=$(hostname -I | awk 'NR==1 {print $1}')
PARSED_IP_ADDR_SINGLE_POD=$(sed -e "s/\./, /g" <<< ${IP_ADDR_SINGLE_POD})
echo $PARSED_IP_ADDR_SINGLE_POD