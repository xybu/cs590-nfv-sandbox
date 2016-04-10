#!/usr/bin/python3

import os
import signal
import subprocess
import sys
import time

import spur

# This is actually a watered-down version bare metal script (w/o tcpreplay)
# optimized for running on remote host to control virtual machine using single
# SSH connection and as little resource as possible.
#
# VM config has been set and VM has been boot by test script.


script_dir = os.path.dirname(os.path.realpath(__file__))
script_dirname = os.path.basename(script_dir)
vm_ip = sys.argv[1]
vm_tmpdir, vm_data_dirname = os.path.split(sys.argv[2])
vm_nic = sys.argv[3]
vm_swappiness = sys.argv[4]
stat_interval = sys.argv[5]
suricata_logdir = sys.argv[6]

sh = spur.SshShell(hostname=vm_ip, username='root', missing_host_key=spur.ssh.MissingHostKey.accept,
	load_system_host_keys=True, look_for_private_keys=True)

def simple_call(cmd):
	return sh.run(cmd, stdout=sys.stdout.buffer, stderr=sys.stdout.buffer, allow_error=True).return_code

def remake_dir(path):
	simple_call(['rm', '-rfv', path])
	simple_call(['mkdir', '-p', path])

# Adjust swappiness
simple_call(['sudo', 'sysctl', '-w', 'vm.swappiness', str(vm_swappiness)])
simple_call(['sysctl', 'vm.swappiness'])

# Rebuild log dir.
remake_dir(vm_tmpdir)
remake_dir(suricata_logdir + '/' + vm_data_dirname)
simple_call(['sync'])

# Configure NIC.
for optarg in ('tso', 'gro', 'lro', 'gso', 'rx', 'tx', 'sg'):
	simple_call(['sudo', 'ethtool', '-K', vm_nic, optarg, 'off'])

# Copy test script to VM.
subprocess.call(['rsync', '-zvrpE', script_dir, 'root@%s:%s' % (vm_ip, vm_tmpdir)])

# Start monitors. Send SIGINT to this script to stop.
with open('suricata.out', 'wb') as suricata_out:
	try:
		sysmon_p = sh.spawn([vm_tmpdir + '/' + script_dirname + '/sysmon.py', '--nic', vm_nic, '--delay', str(stat_interval), '--suffix', '.vm'],
			cwd=vm_tmpdir+'/'+vm_data_dirname, stdout=sys.stdout.buffer, stderr=sys.stdout.buffer, store_pid=True, allow_error=True)
		psmon_p = sh.spawn([vm_tmpdir + '/' + script_dirname + '/psmon.py', '--keywords', 'suricata', '--delay', str(stat_interval), '--out', 'psstat.suricata.csv'],
			cwd=vm_tmpdir+'/'+vm_data_dirname, stdout=sys.stdout.buffer, stderr=sys.stdout.buffer, store_pid=True, allow_error=True)
		suricata_p = sh.spawn(['suricata', '-l', suricata_logdir, '-i', vm_nic],
			stdout=suricata_out, stderr=suricata_out, store_pid=True, allow_error=True)
		while True:
			time.sleep(3600)
	except KeyboardInterrupt:
		suricata_p.send_signal(signal.SIGTERM)
		suricata_p.wait_for_result()
	finally:
		sysmon_p.send_signal(signal.SIGINT)
		psmon_p.send_signal(signal.SIGINT)
		for p in (sysmon_p, psmon_p):
			p.wait_for_result()
