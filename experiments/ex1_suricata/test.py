#!/usr/bin/python3

from datetime import datetime
import subprocess
import sys
import time


LOCAL_NIC = 'macvtap0'

VM_NAME = 'suricata-vm'
VM_IPADDR = '192.168.1.2'
VM_USER = 'root'
VM_NIC = 'eth0'

REMOTE_HOST = 'cap09'
REMOTE_USER = 'bu1'


class Colors:
    MAGENTA = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    CYAN = '\033[96m'
    ENDC = '\033[0m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def now():
	return '[' + str(datetime.today()) + '] '


def prepare_nic(prepend_cmd=[], nic='em2'):
	def call_cmd(args):
		print(now() + ' '.join(args))
		subprocess.call(args)
	call_cmd(prepend_cmd + ['ip', 'link', 'set', nic, 'promisc', 'on'])
	for arg in ['tso', 'gro', 'lro', 'gso', 'rx', 'tx', 'sg']:
		call_cmd(prepend_cmd + ['ethtool', '-K', nic, arg, 'off'])


def prepare_sender(host=REMOTE_HOST, user=REMOTE_USER):
	print(Colors.MAGENTA + now() + 'Updating sender host...' + Colors.ENDC)
	subprocess.call(['rsync', '-vrpE', './sender_scripts', '%s@%s:/tmp/' % (user, host)])
	subprocess.call(['ssh', '%s@%s' % (user, host), '/tmp/sender_scripts/update_traces.sh'])
	print()

def start_vm():
	print(Colors.MAGENTA + now() + 'Starting virtual machine "%s".' % VM_NAME + Colors.ENDC)
	if subprocess.call(['virsh', 'start', VM_NAME]) == 0:
		print(Colors.MAGENTA + now() + 'Sleeping for 30 seconds for VM stabilization.' + Colors.ENDC)
		time.sleep(30)
	prepare_nic(['ssh', '%s@%s' % (VM_USER, VM_IPADDR)], VM_NIC)


def stop_vm():
	print(Colors.MAGENTA + now() + 'Shutting down virtual machine "%s".' % VM_NAME + Colors.ENDC)
	if subprocess.call(['virsh', 'shutdown', VM_NAME]) == 0:
		print(Colors.MAGENTA + now() + 'Sleeping for 30 seconds for VM termination.' + Colors.ENDC)
		time.sleep(30)


def handle_test(line):
	engine, trace, nworker, nrepeat, nround = line.split()
	for i in range(0, int(nround)):
		print(Colors.MAGENTA + now() + 'Experiment {%s, %s, %s, %s}, round %d' % (engine, trace, nworker, nrepeat, i) + Colors.ENDC)
		subprocess.call(['./test_%s.sh' % engine, trace, nworker, nrepeat])


def do_tests(filename='all_tests.lst'):
	with open(filename, 'r') as f:
		for line in f:
			line = line.strip()
			if len(line) == 0 or line.startswith('#'):
				continue
			if line == '@start-vm':
				start_vm()
			elif line == '@stop-vm':
				stop_vm()
			else:
				handle_test(line)


def cleanup():
	print('\n' + Colors.RED + now() + 'Interrupted. Cleaning up.' + Colors.ENDC)
	subprocess.call(['ssh', '%s@%s' % (REMOTE_USER, REMOTE_HOST), 'sudo', 'pkill', '-9', 'tcpreplay'])
	subprocess.call(['ssh', '%s@%s' % (REMOTE_USER, REMOTE_HOST), 'sudo', 'pkill', '-9', 'atop'])


def main():
	try:
		prepare_sender()
		prepare_nic(prepend_cmd=['sudo'], nic='em2')
		prepare_nic(prepend_cmd=['sudo'], nic=LOCAL_NIC)
		do_tests()
	except KeyboardInterrupt:
		cleanup()


if __name__ == '__main__':
	main()
