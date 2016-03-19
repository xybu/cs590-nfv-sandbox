#!/bin/bash

# Run Suricata directly.

LOG_DIR="logs.$(date +%Y%m%dT%H%M%S.%N)"
mkdir $LOG_DIR

exec sudo suricata -l $(pwd)/$LOG_DIR -i vnet0 -i virbr0
