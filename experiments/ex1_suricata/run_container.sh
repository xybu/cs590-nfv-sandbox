#!/bin/bash

LOG_DIR="container_logs/logs.$(date +%Y%m%dT%H%M%S.%N)"

# rm -rfv container_logs
mkdir -p $LOG_DIR

docker run -it --name suricata --rm --net=host -v $(pwd)/$LOG_DIR:/var/log/suricata xybu:suricata suricata -i vnet0 -i virbr0 #/bin/bash
# docker run -it --rm --net=host xybu:suricata /bin/bash
