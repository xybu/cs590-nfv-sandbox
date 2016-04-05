#!/bin/bash

# Run this script on sender host to pull the latest traces.
# @author	Xiangyu Bu <bu1@purdue.edu>

TRACE_HOST_ADDR="cap06"
TRACE_HOST_USER="bu1"
TRACE_REPO_PARENT="/scratch/bu1"
TRACE_REPO_NAME="traces"

LOCAL_TRACE_PARENT="/scratch/bu1"

if [ -d "$LOCAL_TRACE_PARENT/$TRACE_REPO_NAME" ] ; then
	echo -e "\033[94mPolling most recent changes...\033[0m"
	hg pull --cwd=$LOCAL_TRACE_PARENT/$TRACE_REPO_NAME
	hg update --cwd=$LOCAL_TRACE_PARENT/$TRACE_REPO_NAME
	echo -e "\033[92mUpdated traces repo.\033[0m"
else
	echo -e "\033[93mTraces repository did not exist. Creating repo...\033[0m"
	hg clone --cwd=$LOCAL_TRACE_PARENT ssh://$TRACE_HOST_USER@$TRACE_HOST_ADDR$TRACE_REPO_PARENT/$TRACE_REPO_NAME
	echo -e "\033[92mCreated traces repository at $LOCAL_TRACE_PARENT/$TRACE_REPO_NAME.\033[0m"
fi
