#!/bin/bash

# Execute tcpreplay.
# Usage: 
#   ./run_trace.sh TRACEFILE NWORKER NREPEAT

WORKDIR="/tmp/tracerunner"
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

echo $TRACEFILE > traceinfo

for ((n=0;n<$NWORKER;n++)); do
	create_single_worker $n &
done

log "\033[94mWaiting for all child processes...\033[0m"
wait
log "\033[92mTrace replay is complete.\033[0m"
