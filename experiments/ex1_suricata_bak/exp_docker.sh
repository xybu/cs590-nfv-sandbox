#!/bin/bash

# Run a single instance of Docker experiment.
#
# NOTES
#   For automated execution, sudo must not ask for password. run_trace.sh in 
#   the sender VM must not ask for password.
#
# USAGE
#   exp_docker.sh TRACEFILE NWORKER NREPEAT
#
# AUTHOR
#   Xiangyu Bu <bu1@purdue.edu>

# The directory to hold all traces.
TRACE_DIR="/scratch/bu1/traces"

# The remote directory to execute run_trace.sh.
REMOTE_WORKDIR="/home/xb"

# The remote directory to save tcpreplay output.
REMOTE_TCPREPLAY_DIR="/tmp/tcpreplay_out"

# How many tcpreplay instances to run simultaneously.
NWORKER=$2

# How many times to repeat the trace.
NREPEAT=$3

# Docker container name
CONTAINER_NAME="suricata"

# Clean up any residual stuff
echo -e "\033[0mCleaning up before starting..."
echo -e -n "\033[30m"
docker rm -f $CONTAINER_NAME
echo -e -n "\033[0m"

# Start sender VM if not started already.
virsh start ubuntu1

# Transfer the specified trace file.
rsync -vpE ./run_trace.sh xb@10.0.0.101:$REMOTE_WORKDIR/run_trace.sh
rsync -vp $TRACE_DIR/$1 xb@10.0.0.101:$REMOTE_WORKDIR/$1

# Prepare Suricata log dir.
LOG_DIR="docker.logs.$(date +%Y%m%d.%H%M%S)"
mkdir $LOG_DIR

# Start Suricata in a Docker container.
echo -e "\033[94mStarting Suricata in Docker...\033[0m"
# docker run -itd --name $CONTAINER_NAME --net=host -v $(pwd)/$LOG_DIR:/var/log/suricata xybu:suricata /bin/bash -c "suricata -i vnet0 -i virbr1 &> /var/log/suricata/suricata.out" #/bin/bash

docker run -i --name $CONTAINER_NAME --net=host -v $(pwd)/$LOG_DIR:/var/log/suricata xybu:suricata suricata -i vnet0 -i virbr1 &> $(pwd)/$LOG_DIR/suricata.out &

# Wait until Suricata initializes.
while [ ! -f $(pwd)/$LOG_DIR/eve.json ] ; do
	sleep 0.1
done

# Start tcpreplay.
ssh xb@10.0.0.101 $REMOTE_WORKDIR/run_trace.sh $1 $NWORKER $NREPEAT

# Stop Suricata.
echo -e "\033[94mStopping Docker container...\033[0m"
sleep 5
# docker exec --privileged $CONTAINER_NAME pkill -15 suricata
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME

# Copy some logs back to host. The path must correspond to run_trace.sh.
rsync -vrpE xb@10.0.0.101:$REMOTE_TCPREPLAY_DIR $(pwd)/$LOG_DIR/

# virsh reboot ubuntu1

# Clean up.
echo -e "\033[92mDone. Logs saved in \"$LOG_DIR\".\033[0m"
