#!/bin/bash

# Write a log line prepended with datetime.
# Usage: log LINE
function log() {
  echo -e "\033[96m[$(date '+%Y-%m-%d %H:%M:%S.%N')]\033[0m $1"
}

# Configure a NIC for Suricata.
# Usage: setup_nic NIC
function setup_nic() {
  log "Configuring NIC $1..."
  sudo ip link set $1 promisc on
  for arg in "tso" "gro" "lro" "gso" "rx" "tx" "sg" ; do
    sudo ethtool -K $1 $arg off
  done
  log "Successfully configured NIC $1."
}

# Add a new macvtap device which is equivalent to libvirt's macvtap passthru.
# Usage: add_macvtap em2 macvtap0
function add_macvtap() {
  DEV=$1
  TAP=$2
  MAC="52:54:$(echo $DEV | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\).*$/\1:\2:\3:\4/')"
  log "Adding macvtap device $TAP on $DEV."
  sudo ip link add link $DEV name $TAP type macvtap mode passthru
  sudo ip link set $TAP address $MAC up
  sudo ip link show $TAP
}

# Delete a macvtap device.
# Usage: del_macvtap macvtap0
function del_macvtap() {
  TAP=$1
  log "Deleting macvtap device $TAP..."
  sudo ip link del $TAP
}

# Wait for Suricata to initialize.
# Usage: wait_suricata
function wait_suricata() {
  while [ ! -f $LOG_DIR/eve.json ] ; do
    echo "Waiting for Suricata to initialize..."
    sleep 5
  done
  log "Suricata is ready."
}

# Wait for the specified PID to finish.
# Usage: wait_pid PID
function wait_pid() {
  log "Waiting for PID $1 to complete..."
  ps -p$1 &>/dev/null
  while [ "$?" -eq "0" ] ; do
    sleep 2
    log "Waiting for PID $1 to complete..."
    ps -p$1 &>/dev/null
  done
}

# Start tcpreplay on sender host.
function run_trace() {
	ssh $SENDER_USER@$SENDER_HOST $SENDER_SCRIPT_DIR/run_trace.sh $TRACEFILE $NWORKER $NREPEAT
}

# Copy tcpreplay log back.
# Required variables: $LOG_DIR.
function post_copy() {
	rsync -vrpE $SENDER_USER@$SENDER_HOST:$SENDER_TRACELOG $LOG_DIR/
}
