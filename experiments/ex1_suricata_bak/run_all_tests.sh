#!/bin/bash

while read enabled engine trace nworker nrepeat ntests
do
  if [ "$enabled" -gt "0" ] ; then
  	for ((i=0;i<$ntests;i++)); do
  		echo -e "\033[94m[$(date "+%Y-%m-%d %H:%M:%S%z")]\033[0m Run test {$engine, $trace, nworker=$nworker, nrepeat=$nrepeat, round=$i}"
  		/bin/bash -c "./exp_$engine.sh $trace $nworker $nrepeat"
  	done
  fi
done < all_tests
