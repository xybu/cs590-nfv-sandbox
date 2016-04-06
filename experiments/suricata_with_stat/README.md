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

#### Virtual Machine

The virtual machine hardware is configurable. When running tests, different CPU and RAM configuration may be passed as parameters of the test script. By default, it is configured to have access to all 4 cores of the host CPU and have 2 GB of RAM. The XML configurations are available in `config/`. Two NICs are created -- one as macvtap of em2 (NIC for receiving test traffic) with source mode "passthrough", one as a bridge network for remote access to the VM.

The virtual disk has size of 60 GiB, large enough to hold logs of GB magnitude.

#### Topology Setup

##### Bare metal Setup

In bare metal setting, Suricata will run directly on top of hardware and inspect the NIC interface that the test traffic enters.

##### Docker Setup

In Docker setting, the container is configured so that the network interfaces of the host is exposed to the container, enabling Suricata to inspect the same NIC interface as in bare metal setting.

##### Docker-vtap Setup

In Docker-vtap setting, we create a macvtap of mode "passthrough" to copy the traffic arriving at host's em2, and let Suricata in Docker inspect the traffic on the macvtap device.

##### VM Setup
 
 In virtual machine setting, we create a macvtap of mode "passthrough" to copy the traffic arriving at host's em2 to VM's eth0. 

### Special Notes

 * To use streamlined test script, host user and sender must be
   able to run sudo without password prompt (`sudo visudo` and add `username ALL=(ALL) NOPASSWD: ALL`).

 * Use SSH authorized_keys to facilitate SSH login.

## Experiments

