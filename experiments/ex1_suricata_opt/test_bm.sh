#!/bin/bash

# Usage:
#   test_bm.sh bigFlows.pcap 16 3 [--nic=em2] [--use-vtap] [--stat=4]

source ./config/config.$(hostname).ini
source ./framework.sh

TRACEFILE=$1
NWORKER=$2
NREPEAT=$3

TEST_NIC="em2"
USE_VTAP=false
ENABLE_STAT=false

for i in ${@:4} ; do
	case $i in
		-n=*|--nic=*)
			TEST_NIC="${i#*=}"
			shift
			;;
		--use-vtap)
			USE_VTAP=true
			;;
		--stat=*)
			ENABLE_STAT=true
			STAT_INTERVAL="${i#*=}"
			shift
			;;
		*)
			echo -e "\033[91mError: unknown argument $i\033[0m"
			;;
	esac
done

# Configure NIC and VTAP.
setup_nic $TEST_NIC
if [ $USE_VTAP ] ; then
	del_macvtap macvtap0
	add_macvtap $TEST_NIC macvtap0
	TEST_NIC="macvtap0"
fi

LOG_DIR="$(pwd)/logs,bm,$TEST_NIC,$TRACEFILE,$NWORKER,$NREPEAT,$(date +%Y%m%d.%H%M%S),$ENABLE_STAT"

function pre_clean() {
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
	# Remove VTAP device.
	if [ $USE_VTAP ] ; then
		del_macvtap $TEST_NIC
	fi
}

pre_clean
start_test
run_trace $TRACEFILE $NWORKER $NREPEAT
post_clean
post_copy
