#!/bin/bash

# Execute tcpreplay.
# Usage: 
#   ./run_trace.sh TRACEFILE NWORKER NREPEAT

WORKDIR="/tmp/tcpreplay.result"
NIC="em2"
TRACEFILE="/scratch/bu1/traces/$1"
NWORKER=$2
NREPEAT=$3

sudo pkill -9 tcpreplay
rm -rfv $WORKDIR
mkdir -p $WORKDIR

cd $WORKDIR

function log() {
	echo -e "\033[96m[$(date '+%Y-%m-%d %H:%M:%S.%N')]\033[0m $1"
}

function create_single_worker() {
	for ((i=0;i<$NREPEAT;i++)); do
		log "Worker $1, round $i - $TRACEFILE..."
		sudo tcpreplay -i $NIC $TRACEFILE > inst$1.$i.out
	done
}

# Use atop to gather NIC throughput info.
sudo atop -PNET 5 &> atop.out &
atop_pid=$!

# Create tcpreplay workers.
pids=""
for ((n=0;n<$NWORKER;n++)); do
	create_single_worker $n &
	pids="$pids $!"
done

log "\033[94mWaiting for all child processes...\033[0m"

# Wait for each worker process to finish.
for pid in $pids ; do
	wait $pid
done 

log "\033[92mTrace replay completed.\033[0m"

sleep 1

# Stop atop
sudo pkill -15 atop
wait $atop_pid

# Process atop data.
grep $NIC atop.out | tr -s '[:blank:]' ',' > atop.$NIC.csv
