#!/bin/bash

# Prepare the sender machine.

REMOTE_HOST="cap07"
REMOTE_USER="bu1"

# Copy scripts to sender machine.
rsync -vrpE ./sender_scripts $REMOTE_USER@$REMOTE_HOST:/tmp/

# Update sender's copy of trace repository.
ssh $REMOTE_USER@$REMOTE_HOST /tmp/sender_scripts/update_traces.sh
