#!/bin/bash
IP_ADDR_SINGLE_POD=$(hostname -I)
PARSED_IP_ADDR_SINGLE_POD=$(sed -e "s/\./, /g" <<< ${IP_ADDR_SINGLE_POD})
echo $PARSED_IP_ADDR_SINGLE_POD