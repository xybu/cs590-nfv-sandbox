#!/bin/bash

# Run a single instance of bare metal experiment.
#
# NOTES
#   For automated execution, sudo must not ask for password. run_trace.sh in 
#   the sender VM must not ask for password.
#
# USAGE
#   exp_bm.sh TRACEFILE NWORKER NREPEAT
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

# Start sender VM if not started already.
sudo pkill -15 Suricata-Main 
virsh start ubuntu1

# Transfer the specified trace file.
rsync -vpE ./run_trace.sh xb@10.0.0.101:$REMOTE_WORKDIR/run_trace.sh
rsync -vp $TRACE_DIR/$1 xb@10.0.0.101:$REMOTE_WORKDIR/$1

# Prepare Suricata log dir.
LOG_DIR="bm.logs.$(date +%Y%m%d.%H%M%S)"
mkdir $LOG_DIR

# Start Suricata on host.
echo -e "\033[94mStarting Suricata...\033[0m"
sudo suricata -l $(pwd)/$LOG_DIR -i vnet0 -i virbr1 &> $(pwd)/$LOG_DIR/suricata.out &
suricata_pid=$!

# Wait for 1sec to ensure Suricata initializes.
while [ ! -f $(pwd)/$LOG_DIR/eve.json ] ; do
	sleep 0.1
done

# Start tcpreplay.
ssh xb@10.0.0.101 $REMOTE_WORKDIR/run_trace.sh $1 $NWORKER $NREPEAT

# Stop Suricata.
echo -e "\033[94mStopping Suricata...\033[0m"
sleep 5
sudo kill -15 $suricata_pid
sleep 1
sudo pkill -15 Suricata-Main

# Copy some logs back to host. The path must correspond to run_trace.sh.
rsync -vrpE xb@10.0.0.101:$REMOTE_TCPREPLAY_DIR $(pwd)/$LOG_DIR/

# virsh reboot ubuntu1

# Clean up.
echo -e "\033[92mDone. Logs saved in \"$LOG_DIR\".\033[0m"
