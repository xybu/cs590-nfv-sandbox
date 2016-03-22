#!/bin/bash

# This script is intended to run inside sender VM.
# Usage: run.sh TRACEFILE NWORKER NREPEAT

TRACEFILE=$1
NWORKER=$2
NREPEAT=$3

rm -rfv /tmp/tcpreplay_out
mkdir -p /tmp/tcpreplay_out

cd ~

function create_single_worker() {
	for ((i=0;i<$NREPEAT;i++)); do
		echo "Worker $1, round $i - $TRACEFILE..."
		sudo tcpreplay -i eth0 $TRACEFILE > /tmp/tcpreplay_out/$TRACEFILE.$1.$i.out
	done
}

for ((n=0;n<$NWORKER;n++)); do
	create_single_worker $n &
done

echo -e "\033[94mWaiting for all child processes...\033[0m"
wait

echo -e "\033[92mAll done.\033[0m"
