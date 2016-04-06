# Experiment with Suricata

## Intro

We want to compare performance of [Suricata](http://suricata-ids.org/) in bare metal, Docker container, and virtual machine environments, and in different resource allocation configurations.

### Method

Use [tcpreplay](http://tcpreplay.appneta.com/) to replay some Pcap traffic files collected from the Internet, and analyze performance of Suricata (running in bare metal, Docker, and VM, respectively) from statistics it reports and from external sources like [atop](http://linux.die.net/man/1/atop) and [top](http://linux.die.net/man/1/top).

When comparing Docker container and VM, we will also tune the resource limit and see how Suricata will perform.

#### Hardware

There are two pairs of test machines -- (cap03, cap09) and (cap06, cap07). cap03 and cap06 are hosts to run Suricata, while cap09 and cap07 are hosts to run tcpreplay (which is CPU intensive). The two hosts of each pair are connected directly by an Ethernet cable.

All four machines have the following configuration:

 * CPU: Intel Xeon X3430 @ 2.40GHz CPU (Performance mode; [EIST](https://en.wikipedia.org/wiki/SpeedStep)/C-states disabled)
 * RAM: 2 x 2 GB of DDR3-1333 RAM
 * HDD: 500GB Seagate 3.5" 7200RPM + 2*1TB Seagate 3.5" 7200RPM
 * Network: 2 x Broadcom 1Gbps NIC. **em1** is used for remote access and management, and **em2** is used to connect sender host and receiver host (i.e., where test traffic flows).
 * OS: Ubuntu Server 14.04.4 64-bit

#### Software

The versions of the software packages we are to use are:

|     Package      |    Host    |  Docker   |     VM      |
|  --------------  |  --------  | --------  |  ---------  |
|     Docker       |   1.10.3   |     -     |    -        |
|     libvirt      |   1.2.2    |     -     |    -        |
|     gcc          |   4.8.4    |   4.8.4   |   4.8.4     |
|     Suricata     |  3.0.1 Rel | 3.0.1 Rel |  3.0.1 Rel  |
|  Emerging Rules  |   20160405 |  20160405 |   20160405  |
|     TCPreplay    |   4.1.1    |    -      |   4.1.1     |

#### Suricata

Suricata loads the free version of [Emerging Rules](http://rules.emergingthreats.net/open/suricata/) as of 2016-04-05.

Unless otherwise noted, Suricata uses default configuration generated when installed to the system.

Suricata 3.0.1, released on April 4, 2016, [fixed many memory leak bugs and improved stability](http://suricata-ids.org/news/). This can be confirmed by our previous testing of 3.0 version inside VM setup, which resulted in thrashing and can barely be tested.

#### Trace files

We use the following flows available from the Internet:

 * [Sample flows provided by TCPreplay](http://tcpreplay.appneta.com/wiki/captures.html) -- `bigFlows.pcap` (359,457 KB), `smallFlows.pcap` (9,224 KB).
 * [Sample traces collected by WireShark](https://wiki.wireshark.org/SampleCaptures)
 * [Publicly available PCAP files](http://www.netresec.com/?page=PcapFiles)
 * [ISTS'12 trace files](http://www.netresec.com/?page=ISTS) -- randomly picked `snort.log.1425823194` (155,823 KB).

#### Topology Setup

##### Bare metal Setup

In bare metal setting, Suricata will run directly on top of hardware and inspect the NIC interface that the test traffic enters.

![Bare metal setup](https://rawgithub.com/xybu/cs590-nfv-sandbox/master/experiments/suricata_with_stat/readme_src/bare_metal.svg)

##### Docker Setup

In Docker setting, the container is configured so that the network interfaces of the host is exposed to the container, enabling Suricata to inspect the same NIC interface as in bare metal setting.

The CPU and RAM limitations can be passed as parameters of the test script. By default, it allows the container to access all 4 cores and has a RAM limit of 2GB.

![Docker setup](https://rawgithub.com/xybu/cs590-nfv-sandbox/master/experiments/suricata_with_stat/readme_src/Docker_direct.svg)

##### Docker-vtap Setup

In Docker-vtap setting, we create a macvtap of mode "passthrough" to copy the traffic arriving at host's em2, and let Suricata in Docker inspect the traffic on the macvtap device.

The CPU and RAM limitations can be passed as parameters of the test script. By default, it allows the container to access all 4 cores and has a RAM limit of 2GB.

![Docker-vtap setup](https://rawgithub.com/xybu/cs590-nfv-sandbox/master/experiments/suricata_with_stat/readme_src/Docker_vtap.svg)

##### VM Setup

The virtual machine hardware is configurable. Different CPU and RAM configuration may be passed as parameters of the test script. By default, it is configured to have 4 vCPUs each of which has access to all 4 cores of the host CPU. Capacities of vCPU is copied from host CPU ("host-passthrough"). RAM is set to 2 GB by default. The XML configurations are available in [`config/`](config/). In terms of NIC, We create a macvtap device (macvtap0) of mode "passthrough" to copy the test traffic arriving at host's em2 to VM's eth0. Another NIC, eth1, is added for communications between test control process and the VM.

The virtual disk has size of 60 GiB, large enough to hold logs of GB magnitude.

![VM setup](https://rawgithub.com/xybu/cs590-nfv-sandbox/master/experiments/suricata_with_stat/readme_src/vm.svg)

### Special Notes

 * To use streamlined test script, host user and sender must be
   able to run sudo without password prompt (`sudo visudo` and add `username ALL=(ALL) NOPASSWD: ALL`).

 * Use SSH authorized_keys to facilitate SSH login.

## Results

### Bare Metal, bigFlows.pcap, 1xTCPreplay



### Bare Metal, bigFlows.pcap, 2xTCPreplay

### Bare Metal, bigFlows.pcap, 4xTCPreplay

### Docker, bigFlows.pcap, 1xTCPreplay

### Docker, bigFlows.pcap, 2xTCPreplay

### Docker, bigFlows.pcap, 4xTCPreplay

### Docker-vtap, bigFlows.pcap, 1xTCPreplay

### Docker-vtap, bigFlows.pcap, 2xTCPreplay

### Docker-vtap, bigFlows.pcap, 4xTCPreplay

### VM, bigFlows.pcap, 1xTCPreplay

### VM, bigFlows.pcap, 2xTCPreplay

### VM, bigFlows.pcap, 4xTCPreplay
