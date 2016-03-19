Experiment 1
============

## Introduction

This experiment intends to compare performance of Suricata running on three
different environments:

 - directly on host (Ubuntu 14.04.4 bare metal)
 - inside Docker container (Ubuntu 14.04.4 Container)
 - inside QEMU/KVM virtual machine (Ubuntu 14.04.4 VM, ubuntu3)

by replaying different TCP pcap traces inside a guest VM (Ubuntu 14.04.4, ubuntu1).

The guest VM to replay traffic is on the same physical machine as Suricata / Docker /  ubuntu3 VM.

## Configuration

### Package Versions

|  Package   |   Host   |  Docker  |   VM   |
| ---------- | -------- | -------- | ------ |
|  Docker    |  1.10.3  |     -    |   -    |
|  libvirt   |  1.2.2   |     -    |   -    |
|  gcc       |  4.8.4   |   4.8.4  |   -    |
|  Suricata  |  3.0 Rel |  3.0 Rel |   -    |
|  TCPreplay |  4.1.1   |    -     |  4.1.1 |

### Resource Allocation

* Sender VM uses two vCPUs and 1 GiB RAM.
* Suricata running in host OS has no restriction on CPU or RAM usage.
* Docker container of Suricata has no restriction on CPU or RAM usage.
* VM of Suricata uses four vCPUs (all cores) and 1 GiB RAM.

Suricata uses default configuration, allocating 8 processing threads and 
4 management threads.

### Special Config

 * To use streamlined test script (`exp_*.sh`), host user and sender must be
   able to run sudo without password prompt (`sudo visudo` and add `username ALL=(ALL) NOPASSWD: ALL`).

 * Use SSH authorized_keys to facilitate SSH login.

### Topology

 * Sender (tcpreplay) runs in Ubuntu VM with IP address 10.0.0.101 and virtual NIC vnet0.

 * There is no receiver.

 * When running bare metal or in Docker container, Suricata monitors vnet0 directly.

 * When running in Ubuntu VM, Suricata monitors eth0 and traffic from vnet0 is mirrored there.

### Result

#### 

## Further

 - [ ] Use pytbull to test IDS.


Bare Metal
==========

8 threads + 4 mgmt threads.

No limit on memory.

Trace -  snort.log.1425823194

Log - logs.2016-03-18T21:32:38,185710632-0400

```
xb@ubuntu1:~/traces$ sudo tcpreplay -i eth0 snort.log.1425823194
Actual: 142202 packets (157287081 bytes) sent in 22.08 seconds.
Rated: 6891000.0 Bps, 55.12 Mbps, 6230.14 pps
Flows: 1833 flows, 80.30 fps, 140196 flow packets, 2006 non-flow
Statistics for network device: eth0
        Successful packets:        142202
        Failed packets:            0
        Truncated packets:         0
        Retried packets (ENOBUFS): 0
        Retried packets (EAGAIN):  0
```

Trace - bigFlows.pcap

Log - logs.2016-03-18T21:35:23,719524404-0400

```
xb@ubuntu1:~/traces$ sudo tcpreplay -i eth0 bigFlows.pcap
Actual: 791615 packets (355417784 bytes) sent in 303.06 seconds.
Rated: 1170400.0 Bps, 9.36 Mbps, 2607.03 pps
Flows: 40686 flows, 133.99 fps, 791179 flow packets, 436 non-flow
Statistics for network device: eth0
        Successful packets:        791615
        Failed packets:            0
        Truncated packets:         0
        Retried packets (ENOBUFS): 0
        Retried packets (EAGAIN):  0
```

Docker
======

8 threads + 4 mgmt threads.

Let Docker share host's network config (that is, expose vnet0 and virbr1 to Docker).

