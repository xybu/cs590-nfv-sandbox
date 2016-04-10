#!/usr/bin/python3

import json
import signal
import sys
import time
import docker


cli = docker.Client(base_url='unix://var/run/docker.sock')
with open(sys.argv[2], 'w') as f:
	try:
		for stat in cli.stats(sys.argv[1]):
			stat = stat.decode('utf-8')
			f.write(str(stat))
			data = json.loads(stat)
			cpu_percent = (data['cpu_stats']['cpu_usage']['total_usage'] - data['precpu_stats']['cpu_usage']['total_usage']) / (data['cpu_stats']['system_cpu_usage'] - data['precpu_stats']['system_cpu_usage']) * len(data['cpu_stats']['cpu_usage']['percpu_usage'])
			print(cpu_percent * 100)
	except KeyboardInterrupt:
		pass
