#!/usr/bin/python3

import argparse

from test_suricata import *


class TestSuricataBareMetal(TestSuricataBase):

	def __init__(self, args):
		super().__init__()
		self.args = args
		self.session_id = 'logs,bm,%d,%s,%d,%s,%s,%d,%d' % (int(time.time()), args.trace, args.nworker, args.src_nic,
			args.dest_nic + '.vtap' if args.macvtap else args.dest_nic, args.interval, args.swappiness)
		self.session_tmpdir = RUNNER_TMPDIR + '/' + self.session_id
		self.local_tmpdir = TESTER_TMPDIR + '/' + session_id

	def prework(self):
		self.init_test_session(self.session_id, self.local_tmpdir, self.session_tmpdir, self.args)

	def run(self):
		self.status = self.STATUS_START
		nic = self.args.dest_nic
		dest_nic = self.args.dest_nic
		if self.args.macvtap:
			nic = nic + ',' + self.MACVTAP_NAME
			dest_nic = self.MACVTAP_NAME
		self.sysmon_proc = self.shell.spawn([RUNNER_TMPDIR + '/tester_script/sysmon.py', '--delay', str(self.args.interval), '--nic', nic, '--suffix', '.suricata'],
			cwd=self.session_tmpdir, store_pid=True, allow_error=True)
		self.psmon_proc = self.shell.spawn([RUNNER_TMPDIR + '/tester_script/psmon.py', '--keywords', 'suricata', '--delay', str(self.args.interval), '--out', 'psstat.csv'],
			cwd=self.session_tmpdir, store_pid=True, allow_error=True)
		self.suricata_out = open(self.local_tmpdir + '/suricata.out', 'wb')
		self.suricata_proc = self.shell.spawn(['suricata', '-l', self.session_tmpdir, '-i', dest_nic],
			stdout=self.suricata_out, stderr=self.suricata_out, store_pid=True, allow_error=True)
		self.wait_for_suricata(self.session_tmpdir)
		self.replay_trace(self.local_tmpdir, self.args.trace, self.args.nworker, self.args.src_nic, self.args.interval)
		self.suricata_proc.send_signal(signal.SIGTERM)
		suricata_result = self.suricata_proc.wait_for_result()
		log('Suricata returned with value %d.' % suricata_result.return_code)
		self.suricata_out.close()
		del self.suricata_proc
		del self.suricata_out
		self.sysmon_proc.send_signal(signal.SIGINT)
		self.psmon_proc.send_signal(signal.SIGINT)
		self.sysmon_proc.wait_for_result()
		self.psmon_proc.wait_for_result()
		del self.sysmon_proc
		del self.psmon_proc
		if self.status == self.STATUS_START:
			self.status = self.STATUS_DONE

	def postwork(self):
		log('Postwork...')
		if self.status == self.STATUS_DONE:
			self.upload_test_session(self.session_id, self.local_tmpdir, self.session_tmpdir)

	def cleanup(self):
		log('Cleaning up...')
		self.simple_call(['sudo', 'pkill', '-9', 'python'])
		if hasattr(self, 'sysmon_proc'):
			self.sysmon_proc.send_signal(signal.SIGKILL)
		if hasattr(self, 'psmon_proc'):
			self.psmon_proc.send_signal(signal.SIGKILL)
		if hasattr(self, 'suricata_proc'):
			self.suricata_proc.send_signal(signal.SIGKILL)
		if hasattr(self, 'suricata_out'):
			self.suricata_out.close()
		self.destroy_session(self.session_id, self.local_tmpdir, self.session_tmpdir, self.args)
		self.close()

	def start(self):
		try:
			self.prework()
			self.run()
			self.postwork()
			self.cleanup()
		except KeyboardInterrupt:
			log('Interrupted. Stopping and cleaning...')
			self.cleanup()


def main():
	parser = argparse.ArgumentParser(description='Run Suricata directly on top of remote host and collect system info.')
	parser.add_argument('trace', type=str, help='Name of a trace file in trace repository.')
	parser.add_argument('nworker', type=int, help='Number of concurrent TCPreplay processes.')
	parser.add_argument('--src-nic', '-s', nargs='?', type=str, default='em2', help='Replay trace on this local NIC.')
	parser.add_argument('--dest-nic', '-d', nargs='?', type=str, default='em2', help='Trace will be observed on this NIC on the dest host.')
	parser.add_argument('--macvtap', '-v', default=False, action='store_true', help='If present, create a macvtap device on dest host.')
	parser.add_argument('--interval', '-t', nargs='?', type=int, default=4, help='Interval (sec) between collecting dest host info.')
	parser.add_argument('--swappiness', '-w', nargs='?', type=int, default=5, help='Memory swappiness of the host (e.g., 5).')
	args = parser.parse_args()
	log(str(args))
	TestSuricataBareMetal(args).start()


if __name__ == '__main__':
	main()
