#!/bin/bash

LOG_DIR="docker.logs.$(date +%Y%m%d.%H%M%S)"
TRACEFILE=$1
NWORKER=$2
NREPEAT=$3

CONTAINER_NAME="suricata"

source ./test_frame.sh

function pre_clean() {
	echo -e "\033[0mCleaning up before starting..."
	echo -e -n "\033[30m"
	docker rm -f $CONTAINER_NAME
	echo -e -n "\033[0m"
	mkdir $LOG_DIR
}

function start_test() {
	log "\033[94mStarting Suricata in Docker...\033[0m"
	docker run -i --name $CONTAINER_NAME --net=host -v $(pwd)/$LOG_DIR:/var/log/suricata xybu:suricata suricata -i em2 &> $(pwd)/$LOG_DIR/suricata.out &

	# Wait until Suricata initializes.
	while [ ! -f $(pwd)/$LOG_DIR/eve.json ] ; do
		echo "Waiting for Suricata to initialize..."
		sleep 2
	done
	log "\033[94mSuricata is ready.\033[0m"
}

function post_clean() {
	log "\033[94mStopping Docker container...\033[0m"
	sleep 5
	# docker exec --privileged $CONTAINER_NAME pkill -15 suricata
	docker stop $CONTAINER_NAME
	docker rm $CONTAINER_NAME
}

pre_clean
start_test
run_trace $TRACEFILE $NWORKER $NREPEAT
post_clean
post_copy
