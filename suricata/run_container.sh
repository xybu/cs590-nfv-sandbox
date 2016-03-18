#!/bin/bash

# rm -rfv container_logs
mkdir -p container_logs
docker run -it --rm --net=host -v `pwd`/container_logs:/var/log/suricata xybu:suricata /bin/bash
# docker run -it --rm --net=host xybu:suricata /bin/bash

