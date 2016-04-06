#!/usr/bin/python3

from datetime import datetime
import io
import socket
import subprocess
import sys
import time

HOSTNAME = socket.gethostname()

# Load environment variables from bash INI.
with open('./config/config.%s.ini' % HOSTNAME, 'r') as f:
    for line in f:
        exec(line)


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


def prepare_sender(host, user, remote_script_dir):
	print(Colors.MAGENTA + now() + 'Updating sender host...' + Colors.ENDC)
	subprocess.call(['ssh', '%s@%s' % (user, host), 'mkdir', '-p', remote_script_dir])
	subprocess.call(['rsync', '-vrpE', './sender_scripts/', '%s@%s:%s/' % (user, host, remote_script_dir)])
	subprocess.call(['ssh', '%s@%s' % (user, host), '%s/update_traces.sh' % remote_script_dir])
	print()


def handle_test(line):
	nround, engine, args = line.split(maxsplit=2)
	nround = int(nround)
	args = args.split()
	for i in range(0, nround):
		print(Colors.MAGENTA + now() + 'Experiment {%s %s} - Round %d / %d' % (engine, ' '.join(args), i+1, nround) + Colors.ENDC)
		subprocess.call(['./test_%s.sh' % engine] + args)


def do_tests(filename):
	with open(filename, 'r') as f:
		for line in f:
			line = line.strip()
			if len(line) == 0 or line.startswith('#'):
				continue
			else:
				handle_test(line)


def stop_sender(host, user):
	print('\n' + Colors.RED + now() + 'Interrupted. Cleaning up.' + Colors.ENDC)
	subprocess.call(['ssh', '%s@%s' % (user, host), 'sudo', 'pkill', '-9', 'tcpreplay'])
	subprocess.call(['ssh', '%s@%s' % (user, host), 'sudo', 'pkill', '-9', 'atop'])


def main():
	sender_host = SENDER_HOST
	sender_user = SENDER_USER
	try:
		prepare_sender(host=sender_host, user=sender_user, remote_script_dir=SENDER_SCRIPT_DIR)
		do_tests(filename='./config/tests.%s.txt' % HOSTNAME)
	except KeyboardInterrupt:
		stop_sender(host=sender_host, user=sender_user)


if __name__ == '__main__':
	main()
