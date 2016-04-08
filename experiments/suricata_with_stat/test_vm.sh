#!/bin/bash

# Usage:
#   test_vm.sh bigFlows.pcap 16 3 [--nic=em2] [--stat=4] [--vm-name=suricata-vm] [--vm-ipaddr=192.168.1.2]
#
# Notes:
#   To change the NIC to monitor, edit the VM config in virsh or virt-manager.

source ./config/config.$(hostname).ini
source ./framework.sh

TRACEFILE=$1
NWORKER=$2
NREPEAT=$3

VM_NAME="suricata-vm"
# VM_IPADDR="192.168.122.2"
TEST_NIC="em2"
ENABLE_STAT=false

CPUSET="0-3"
VCPUCOUNT="4"
MEMORY_LIMIT="2g"
MEMORY_SWAPPINESS="5"

# Still need to configure the NICs of the VM manually.
# The script assumes the VM_* fields in config to be the same for all VMs.

for i in ${@:4} ; do
	case $i in
		-n=*|--nic=*)
			TEST_NIC="${i#*=}"
			shift
			;;
		--vm-name=*)
			VM_NAME="${i#*=}"
			shift
			;;
		--vm-ipaddr=*)
			VM_IPADDR="${i#*=}"
			shift
			;;
		--vcpus=*)
			VCPUCOUNT="${i#*=}"
			shift
			;;
		-c=*|--cpus=*)
			CPUSET="${i#*=}"
			shift
			;;
		-m=*|--memory=*)
			MEMORY_LIMIT="${i#*=}"
			if [[ "$MEMORY_LIMIT" == *g ]] ; then
				MEMORY_LIMIT=${MEMORY_LIMIT%?}
				MEMORY_LIMIT=$((MEMORY_LIMIT * 2**20)) # in KiB.
			else 
				if [[ "$MEMORY_LIMIT" == *m ]] ; then
					MEMORY_LIMIT=${MEMORY_LIMIT%?}
					MEMORY_LIMIT=$((MEMORY_LIMIT * 2**10))
				else
					if [[ "$MEMORY_LIMIT" == *k ]] ; then
						MEMORY_LIMIT=${MEMORY_LIMIT%?}
					fi
				fi
			fi
			shift
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

LOG_DIR="$(pwd)/logs,vm,$TEST_NIC,$TRACEFILE,$NWORKER,$NREPEAT,$(date +%Y%m%d.%H%M%S),$VM_NAME,$VCPUCOUNT,$CPUSET,$MEMORY_LIMIT,$MEMORY_SWAPPINESS,$ENABLE_STAT"

setup_nic $TEST_NIC

function shutdown_vm() {
	virsh shutdown $VM_NAME
	if [ "$?" -eq "0" ] ; then
		log "Shutting down VM $VM_NAME and wait for 20 sec..."
		sleep 20
	fi
}

function boot_vm() {
	log "Starting VM $VM_NAME..."

	# Configure CPU and RAM of VM at runtime.
	virsh emulatorpin $VM_NAME $CPUSET --config
	virsh setvcpus $VM_NAME $VCPUCOUNT --config
	for (( i=0 ; i<$VCPUCOUNT ; ++i )) ; do
		virsh vcpupin $VM_NAME --vcpu $i $CPUSET --config
	done
	virsh setmem $VM_NAME $MEMORY_LIMIT --config

	virsh start $VM_NAME

	# Assuming the VM uses DHCP, obtain IP address from DHCP lease list.
	if [ -z "$VM_IPADDR" ] ; then
		log "Wait for 10 sec before probing VM IP address..."
		sleep 10
		VM_IPADDR=$(cat /var/lib/libvirt/dnsmasq/default.leases | grep $VM_NAME)
		# "1460082086 52:54:00:79:ac:0b 192.168.122.227 suricata-vm *""
		VM_IPADDR=$(echo $VM_IPADDR | cut -d ' ' -f3)
		log "Found IP address of VM $VM_NAME from DHCP: $VM_IPADDR."
	fi

	# Wait for VM to start.
	ssh root@$VM_IPADDR echo "Virtual machine $VM_NAME is ready."
	while [ "$?" -ne "0" ] ; do
		log "Waiting for virtual machine to start..."
		sleep 5
		ssh root@$VM_IPADDR echo "Virtual machine $VM_NAME is ready."
	done
	ssh root@$VM_IPADDR sysctl -w vm.swappiness=$MEMORY_SWAPPINESS
}

function pre_clean() {
	shutdown_vm
	boot_vm

	# Clean up the VM.
	log "Cleaning up any residual data in the VM."
	ssh root@$VM_IPADDR pkill -15 Suricata-Main
	ssh root@$VM_IPADDR rm -rfv "$VM_LOG_DIR/*"
	if $ENABLE_STAT ; then
		ssh root@$VM_IPADDR pkill -15 top
		ssh root@$VM_IPADDR pkill -15 atop
		sudo pkill -15 top
		sudo pkill -15 atop
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
	if $ENABLE_STAT ; then
		log "Starting top and atop in VM..."
		# Use network to transfer the log gradually because the VM disk may not
		# be large enough to hold the files.
		ssh root@$VM_IPADDR atop -PCPU,cpu,CPL,MEM,PAG,DSK,NET $STAT_INTERVAL &> $LOG_DIR/atop_vm.out &
		ssh root@$VM_IPADDR top -b -d $STAT_INTERVAL &> $LOG_DIR/top_vm.out &
		sudo atop -PCPU,cpu,CPL,MEM,PAG,DSK,NET $STAT_INTERVAL &> $LOG_DIR/atop.out &
		sudo top -b -d $STAT_INTERVAL &> $LOG_DIR/top.out &
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
	sleep 20
	log "Stopping Suricata..."
  	ssh root@$VM_IPADDR pkill -15 Suricata-Main
  	if $ENABLE_STAT ; then
		log "Stopping top and atop in VM..."
		ssh root@$VM_IPADDR pkill -15 atop
		ssh root@$VM_IPADDR pkill -15 top
		log "Stopping top and atop in host..."
		sudo pkill -15 atop
		sudo pkill -15 top
	fi
	wait
	log "Suricata exit."
	rsync -rvpE "root@$VM_IPADDR:$VM_LOG_DIR/*" $LOG_DIR/
	ssh root@$VM_IPADDR rm -rfv "$VM_LOG_DIR/*"
	ssh root@$VM_IPADDR sync
	virsh cpu-stats $VM_NAME > $LOG_DIR/virsh_cpu_stat.txt
	shutdown_vm
}

pre_clean
start_test
run_trace $TRACEFILE $NWORKER $NREPEAT
post_clean
post_copy
postprocess_atop atop
postprocess_atop atop_vm
postprocess_top top qemu
postprocess_top top_vm suricata
test_complete
