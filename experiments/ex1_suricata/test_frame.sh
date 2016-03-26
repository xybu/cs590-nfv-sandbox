#!/bin/bash

REMOTE_HOST="cap07"
REMOTE_USER="bu1"
REMOTE_TRACELOG='/tmp/tcpreplay.result'

function log() {
  echo -e "\033[96m[$(date '+%Y-%m-%d %H:%M:%S.%N')]\033[0m $1"
}

function wait_pid() {
  log "Waiting for PID $1 to complete..."
  ps -p$1 &>/dev/null
  while [ "$?" -eq "0" ] ; do
    sleep 2
    log "Waiting for PID $1 to complete..."
    ps -p$1 &>/dev/null
  done
}

function run_trace() {
	ssh $REMOTE_USER@$REMOTE_HOST /tmp/sender_scripts/run_trace.sh $TRACEFILE $NWORKER $NREPEAT
}

function post_copy() {
	rsync -vrpE $REMOTE_USER@$REMOTE_HOST:$REMOTE_TRACELOG $(pwd)/$LOG_DIR/
}
