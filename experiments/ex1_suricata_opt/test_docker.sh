#!/bin/bash

# Usage:
#   test_docker.sh bigFlows.pcap 16 3 em2[+vtap] [stat 4]

source ./config/config.$(hostname).ini
source ./framework.sh

TRACEFILE=$1
NWORKER=$2
NREPEAT=$3
CONTAINER_NAME="suricata"

# Parse NIC argument, which is either "em2" or "em2+vtap".
TEST_NIC=$4
echo $TEST_NIC | grep -aob + &> /dev/null
if [ "$?" -eq "0" ] ; then
	# '+' is in NIC name. Create vtap.
	USE_VTAP=true
	TEST_NIC=$(echo $TEST_NIC | cut -d+ -f1)
	setup_nic $TEST_NIC
	# Fix macvtap device's name to macvtap0.
	del_macvtap macvtap0
	add_macvtap $TEST_NIC macvtap0
	TEST_NIC="macvtap0"
	# for i in 0 1 2 .. 20 ; do
	#	ifconfig macvtap$i &> /dev/null
	#	if [ $? -ne "0" ] ; then
	#		add_macvtap $TEST_NIC macvtap$i
	#		TEST_NIC=macvtap$i
	#		break
	#	fi
	# done
	# Hopefully there is a free name in macvtap0 -- macvtap20.
else
	USE_VTAP=false
	setup_nic $TEST_NIC
fi

case $5 in
	on|true|stat)
		ENABLE_STAT=true
		STAT_INTERVAL=$6
		;;
	*)
		ENABLE_STAT=false
		;;
esac

LOG_DIR="$(pwd)/logs,dk,$TEST_NIC,$TRACEFILE,$NWORKER,$NREPEAT,$(date +%Y%m%d.%H%M%S)"

function pre_clean() {
	log "Pre cleaning..."
	docker rm -f $CONTAINER_NAME
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
	log "Starting Suricata in Docker..."
	docker run -i --name $CONTAINER_NAME --net=host -v $LOG_DIR:/var/log/suricata xybu:suricata \
		suricata -i $TEST_NIC &> $LOG_DIR/suricata.out &
	wait_suricata
}

function post_clean() {
	sleep 10
	log "Stopping Docker container..."
	docker stop $CONTAINER_NAME
	docker rm $CONTAINER_NAME
	if [ $ENABLE_STAT ] ; then
		log "Stopping top and atop..."
		sudo kill -15 $atop_pid
		sudo kill -15 $top_pid
	fi
	wait
	del_macvtap macvtap0
}

pre_clean
start_test
run_trace $TRACEFILE $NWORKER $NREPEAT
post_clean
post_copy
