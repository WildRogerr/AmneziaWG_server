#!/bin/bash

INTERFACE=$(ip route show default | awk '{print $5}')
OUTPUT_FILE="/var/lib/zabbix/network_speed.txt"

RX_TX=$(ifstat -i $INTERFACE -b 1 1 | tail -n 1 | awk '{print $1, $2}')

echo "$RX_TX" > "$OUTPUT_FILE"
