#!/bin/bash

# Run a single test.
# Usage:
#   test.sh [bm|docker|vm] TRACEFILE NWORKER NREPEAT NROUND

if [ "$#" -ne "5" ] ; then
	echo -e "\033[91mError: invalid arguments.\033[0m"
	echo -e "Usage:"
	echo -e "  test.sh [bm|docker|vm] TRACEFILE NWORKER NREPEAT NROUND"
	exit 1
fi

source ./prepare_sender.sh
