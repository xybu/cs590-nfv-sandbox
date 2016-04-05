#!/bin/bash

# Usage:
#   test_vm.sh bigFlows.pcap 16 3 [stat 4]
#
# Notes:
#   To change the NIC to monitor, edit the VM config in virsh or virt-manager.

source ./config/config.$(hostname).ini
source ./framework.sh

TRACEFILE=$1
NWORKER=$2
NREPEAT=$3
TEST_NIC="em2"

case $4 in
	on|true|stat)
		ENABLE_STAT=true
		STAT_INTERVAL=$5
		;;
	*)
		ENABLE_STAT=false
		;;
esac

LOG_DIR="logs,vm,$TEST_NIC,$TRACEFILE,$NWORKER,$NREPEAT,$(date +%Y%m%d.%H%M%S)"

function shutdown_vm() {
	virsh shutdown $VM_NAME
	if [ "$?" -eq "0" ] ; then
		log "Shutting down VM $VM_NAME and wait for 20 sec..."
		sleep 20
	fi
}

function boot_vm() {
	log "Starting VM $VM_NAME..."
	virsh start $VM_NAME

	# Wait for VM to start.
	ssh root@$VM_IPADDR echo "Virtual machine $VM_NAME is ready."
	while [ "$?" -ne "0" ] ; do
		log "Waiting for virtual machine to start..."
		sleep 5
		ssh root@$VM_IPADDR echo "Virtual machine $VM_NAME is ready."
	done
}

function pre_clean() {
	shutdown_vm
	boot_vm

	# Clean up the VM.
	log "Cleaning up any residual data in the VM."
	ssh root@$VM_IPADDR pkill -15 Suricata-Main
	ssh root@$VM_IPADDR rm -rfv "$VM_LOG_DIR/*"
	if [ $ENABLE_STAT ] ; then
		ssh root@$VM_IPADDR pkill -15 top
		ssh root@$VM_IPADDR pkill -15 atop
	fi

	rsync -vpE ./framework.sh root@$VM_IPADDR:$VM_SCRIPT_DIR/
	ssh -t root@$VM_IPADDR /bin/bash -s << EOF
		source $VM_SCRIPT_DIR/framework.sh
		setup_nic $VM_NIC
EOF

	# Create local log dir.
	mkdir -p $LOG_DIR
}

function start_test() {
	if [ $ENABLE_STAT ] ; then
		log "Starting top and atop in VM..."
		# Use network to transfer the log gradually because the VM disk may not
		# be large enough to hold the files.
		ssh root@$VM_IPADDR atop -PCPU,cpu,CPL,MEM,PAG,DSK,NET $STAT_INTERVAL &> $LOG_DIR/atop.out &
		ssh root@$VM_IPADDR top -b -d $STAT_INTERVAL &> $LOG_DIR/top.out &
	fi
	log "Starting Suricata in VM..."
	ssh root@$VM_IPADDR suricata -i $VM_NIC &> $LOG_DIR/suricata.out &
	ssh -t root@$VM_IPADDR /bin/bash -s << EOF
		source $VM_SCRIPT_DIR/framework.sh
		LOG_DIR=$VM_LOG_DIR
		wait_suricata
EOF
}

function post_clean() {
	sleep 10
	log "Stopping Suricata..."
  	ssh root@$VM_IPADDR pkill -15 Suricata-Main
  	if [ $ENABLE_STAT ] ; then
		log "Stopping top and atop..."
		ssh root@$VM_IPADDR pkill -15 atop
		ssh root@$VM_IPADDR pkill -15 top
	fi
	wait
	log "Suricata exit."
	rsync -rvpE "root@$VM_IPADDR:$VM_LOG_DIR/*" $LOG_DIR/
	ssh root@$VM_IPADDR rm -rfv "$VM_LOG_DIR/*"
	ssh root@$VM_IPADDR sync
	shutdown_vm
}

pre_clean
start_test
run_trace $TRACEFILE $NWORKER $NREPEAT
post_clean
post_copy
