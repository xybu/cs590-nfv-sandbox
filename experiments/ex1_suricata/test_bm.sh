#!/bin/bash

LOG_DIR="bm.logs.$(date +%Y%m%d.%H%M%S)"
TRACEFILE=$1
NWORKER=$2
NREPEAT=$3

source ./test_frame.sh

function pre_clean() {
	sudo pkill -15 Suricata-Main
	sudo pkill -15 suricata
	mkdir $LOG_DIR
}

function start_test() {
	log "\033[94mStarting Suricata...\033[0m"
	sudo suricata -l $(pwd)/$LOG_DIR -i em2 &> $(pwd)/$LOG_DIR/suricata.out &
	suricata_pid=$!

	# Wait until Suricata initializes.
	while [ ! -f $(pwd)/$LOG_DIR/eve.json ] ; do
		echo "Waiting for Suricata to initialize..."
		sleep 2
	done
	log "\033[94mSuricata is ready.\033[0m"
}

function post_clean() {
	sleep 5
	log "\033[94mStopping Suricata...\033[0m"
	sudo pkill -15 Suricata-Main
	sudo pkill -15 suricata
	wait
}

pre_clean
start_test
run_trace $TRACEFILE $NWORKER $NREPEAT
post_clean
post_copy
