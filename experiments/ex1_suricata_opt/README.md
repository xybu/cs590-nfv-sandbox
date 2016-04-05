Experiment
==========

## Intro

We want to compare the performance of [Suricata](http://suricata-ids.org/) in bare metal, Docker container, and virtual machine environments, and in different resource allocation configurations.

### Method

Use [tcpreplay](http://tcpreplay.appneta.com/) to replay some Pcap traffic files collected from the Internet, and analyze the performance of Suricata (running in bare metal, Docker, and VM, respectively) from the statistics it reports.

When comparing Docker container and VM, we will also tune the resource limit and see how Suricata will perform.

## Configurations

### Hardware

We use two machines -- cap06 and cap07. Both machines have Intel Xeon X3430 @ 2.40GHz CPU (with [EIST](https://en.wikipedia.org/wiki/SpeedStep)/C1E/C3/C6 disabled) and 4 GB of RAM, and run Ubuntu 14.04.4 64-bit. Virtual memory swappiness is set to 10%.

 * *cap06* -- used for running Suricata in bare metal, in Docker, and in a VM, respectively. Also used for running the control process (the control process does nothing when testing Suricata).

 * *cap07* -- dedicated to running `tcpreplay` (as the load generator). It turns out that `tcpreplay` is extremely CPU intensive.

### Software

The versions of the software packages we are to use are:

|     Package      |    Host    |  Docker   |     VM      |
|  --------------  |  --------  | --------  |  ---------  |
|     Docker       |   1.10.3   |     -     |    -        |
|     libvirt      |   1.2.2    |     -     |    -        |
|     gcc          |   4.8.4    |   4.8.4   |   4.8.4     |
|     Suricata     |   3.0 Rel  |  3.0 Rel  |  3.0 Rel    |
|  Emerging Rules  |   20160325 |  20160325 |   20160325  |
|     TCPreplay    |   4.1.1    |    -      |   4.1.1     |

#### Suricata

Suricata loads the free version of [Emerging Rules](http://rules.emergingthreats.net/open/suricata/) as of 2016-03-25.

Unless otherwise noted, Suricata uses default configuration generated when installed to the system.

### Virtual Machine

The virtual machine environment is configured to have access to all 4 cores of the host CPU and have 2 GB of RAM. Two NICs are created -- one as macvtap of em2 (NIC for receiving test traffic) with source mode "passthrough", one as a bridge network for remote access to the VM.

The virtual disk must be large enough to hold logs of GB magnitude.

### Traffic

 * In bare metal setting, Suricata will directly inspect the NIC interface that the trace traffic enters.
 * In Docker setting, the container is configured so that the network interfaces of the host is exposed to the container, enabling Suricata to inspect the same NIC interface as in bare metal setting.
 * In virtual machine setting, we create a macvtap of mode "passthrough" to copy the traffic arriving at host's em2 to VM's eth0. This cost of copyinig traffic is unavoidable when running Suricata inside a VM, but is not needed when running Suricata in Docker (for our configuration) or in bare metal. Therefore, we account the cost only for VM setting.

### Special Treatments

 * To use streamlined test script, host user and sender must be
   able to run sudo without password prompt (`sudo visudo` and add `username ALL=(ALL) NOPASSWD: ALL`).

 * Use SSH authorized_keys to facilitate SSH login.

## Experiments
