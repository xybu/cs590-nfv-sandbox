#!/bin/bash

# Usage:
#   test_docker.sh bigFlows.pcap 16 3 [--nic=em2] [--use-vtap] [--cpus=0-3] [--memory=2g] [--swappiness=10]

source ./config/config.$(hostname).ini
source ./framework.sh

TRACEFILE=$1
NWORKER=$2
NREPEAT=$3

CONTAINER_NAME="suricata"
TEST_NIC="em2"
USE_VTAP=false
ENABLE_STAT=false
CPUSET="0-3"
MEMORY_LIMIT="2g"
MEMORY_SWAPPINESS="5"

for i in ${@:4} ; do
	case $i in
		-n=*|--nic=*)
			TEST_NIC="${i#*=}"
			shift
			;;
		-c=*|--cpus=*)
			CPUSET="${i#*=}"
			shift
			;;
		-m=*|--memory=*)
			MEMORY_LIMIT="${i#*=}"
			shift
			;;
		--use-vtap)
			USE_VTAP=true
			;;
		--swappiness=*)
			MEMORY_SWAPPINESS="${i#*=}"
			shift
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

LOG_DIR="$(pwd)/logs,dk,$TEST_NIC,$TRACEFILE,$NWORKER,$NREPEAT,$(date +%Y%m%d.%H%M%S),$CPUSET,$MEMORY_LIMIT,$MEMORY_SWAPPINESS,$ENABLE_STAT"

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
	docker run -i --name $CONTAINER_NAME \
		--cpuset-cpus=$CPUSET --memory=$MEMORY_LIMIT --memory-swappiness=$MEMORY_SWAPPINESS \
		--net=host -v $LOG_DIR:/var/log/suricata xybu:suricata \
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
