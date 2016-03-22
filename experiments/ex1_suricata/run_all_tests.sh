#!/bin/bash

while read engine trace nworker nrepeat ntests
do
	for ((i=0;i<$ntests;i++)); do
		echo -e "\033[94m[$(date "+%Y-%m-%d %H:%M:%S%z")]\033[0m Run test {$engine, $trace, nworker=$nworker, nrepeat=$nrepeat, round=$i}"
		exp_$engine.sh $trace $nworker $nrepeat
	done
done < all_tests
