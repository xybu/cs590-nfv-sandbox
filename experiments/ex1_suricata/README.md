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

Docker
======

8 threads + 4 mgmt threads.

Let Docker share host's network config (that is, expose vnet0 and virbr1 to Docker).

