#!/bin/bash

# Usage:
#   test_bm.sh bigFlows.pcap 16 3 em2 [stat 4]

source ./config/config.$(hostname).ini
source ./framework.sh

TRACEFILE=$1
NWORKER=$2
NREPEAT=$3
TEST_NIC=$4

case $5 in
	on|true|stat)
		ENABLE_STAT=true
		STAT_INTERVAL=$6
		;;
	*)
		ENABLE_STAT=false
		;;
esac

LOG_DIR="$(pwd)/logs,bm,$TEST_NIC,$TRACEFILE,$NWORKER,$NREPEAT,$(date +%Y%m%d.%H%M%S)"

function pre_clean() {
	setup_nic $TEST_NIC
	$ENABLE_STAT && sudo pkill -15 top
	$ENABLE_STAT && sudo pkill -15 atop
	sudo pkill -15 Suricata-Main
	mkdir -p $LOG_DIR
}

function start_test() {
	if [ $ENABLE_STAT ] ; then
		log "Starting top and atop..."
		sudo atop -PCPU,cpu,CPL,MEM,PAG,DSK,NET $STAT_INTERVAL &> $LOG_DIR/atop.out &
		atop_pid=$!
		sudo top -b -d $STAT_INTERVAL &> $LOG_DIR/top.out &
		top_pid=$!
	fi
	log "Starting Suricata..."
	sudo suricata -l $LOG_DIR -i $TEST_NIC &> $LOG_DIR/suricata.out &
	suricata_pid=$!
	wait_suricata
}

function post_clean() {
	sleep 10
	log "Stopping Suricata..."
	sudo pkill -15 Suricata-Main
	if [ $ENABLE_STAT ] ; then
		log "Stopping top and atop..."
		sudo kill -15 $atop_pid
		sudo kill -15 $top_pid
	fi
	wait
}

pre_clean
start_test
run_trace $TRACEFILE $NWORKER $NREPEAT
post_clean
post_copy
