#!/bin/bash

LOG_DIR="vm.logs.$(date +%Y%m%d.%H%M%S)"
TRACEFILE=$1
NWORKER=$2
NREPEAT=$3

VM_NAME="suricata-vm"
VM_IPADDR="192.168.1.2"
VM_NIC="eth0"
VM_LOGDIR="/var/log/suricata"

source ./test_frame.sh

function pre_clean() {
	# Start the VM
	virsh start $VM_NAME

	# Wait for VM to start.
	ssh root@$VM_IPADDR echo "Virtual machine $VM_NAME is ready."
	while [ "$?" -ne "0" ] ; do
		echo -e "\033[93mWaiting for virtual machine to start...\033[0m"
		sleep 2
		ssh root@$VM_IPADDR echo -e "Virtual machine $VM_NAME is ready."
	done

	# Clean up the VM.
	echo -e "\033[94mCleaning up any residual data in the VM.\033[0m"
	ssh root@$VM_IPADDR pkill -15 Suricata-Main
  ssh root@$VM_IPADDR pkill -15 suricata
	ssh root@$VM_IPADDR rm -rfv "$VM_LOGDIR/*"

	# Create local log dir.
	mkdir $LOG_DIR
}

function start_test() {
	log "\033[94mStarting Suricata...\033[0m"
  ssh root@$VM_IPADDR suricata -i $VM_NIC --pidfile $VM_LOGDIR/suricata.pid &> $(pwd)/$LOG_DIR/suricata.out &
	ssh root@$VM_IPADDR /bin/bash -s << EOF
	 	# ip link set $VM_NIC promisc on
		# Wait until Suricata initializes.
		while [ ! -f $VM_LOGDIR/eve.json ] ; do
			echo "Waiting for Suricata to initialize..."
			sleep 2
		done
EOF
	log "\033[94mSuricata is ready.\033[0m"
}

function post_clean() {
  sleep 5
	log "\033[94mStopping Suricata...\033[0m"
  ssh root@$VM_IPADDR pkill -15 Suricata-Main
  ssh root@$VM_IPADDR pkill -15 suricata
  wait
  log "\033[94mSuricata exit.\033[0m"
	rsync -rvpE "root@$VM_IPADDR:$VM_LOGDIR/*" ./$LOG_DIR/
}

pre_clean
start_test
run_trace $TRACEFILE $NWORKER $NREPEAT
post_clean
post_copy
