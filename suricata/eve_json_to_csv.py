#!/usr/bin/python3

"""
Convert Suricata's eve.json to csv format, prepending execution instance number.

@author	Xiangyu Bu <bu1@purdue.edu>
"""

import csv
import json

last_uptime = -1
last_instance = []
instances = []


def flatten_dict(y):
    out = {}

    def flatten(x, name=''):
        if isinstance(x, dict):
            for a in x:
                flatten(x[a], name + a + '.')
        else:
            out[str(name[:-1])] = x

    flatten(y)
    return out


# Assuming each line is a single event.
with open('eve.json', 'r') as f:
	for line in f:
		ev = json.loads(line)
		if ev['event_type'] == 'stats':
			if ev['stats']['uptime'] < last_uptime:
				# When Suricata restarted, create a new instance.
				instances.append(last_instance)
				last_instance = []
			ev['stats']['timestamp'] = ev['timestamp']
			last_instance.append(flatten_dict(ev['stats']))
			last_uptime = ev['stats']['uptime']

if last_instance not in instances:
	instances.append(last_instance)

with open('eve.csv', 'w') as csvf:
	fieldnames = sorted(instances[-1][-1].keys())
	fieldnames.remove('timestamp')
	fieldnames.remove('uptime')
	fieldnames.insert(0, 'uptime')
	fieldnames.insert(0, 'timestamp')
	fieldnames.insert(0, 'instance')
	writer = csv.DictWriter(csvf, fieldnames=fieldnames)
	writer.writeheader()
	i = 0
	for inst in instances:
		j = 1
		for ev in inst:
			ev['instance'] = i
			writer.writerow(ev)
			print('Instance %d: %d / %d ...' % (i, j, len(inst)), end='\r')
			j += 1
		print()
		i += 1
