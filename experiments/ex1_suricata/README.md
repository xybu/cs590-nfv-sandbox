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
|  Emerging Rules  |   20160324 |  20160324 |   20160324  |
|     TCPreplay    |   4.1.1    |    -      |   4.1.1     |

### Traffic

 * In bare metal setting, Suricata will directly inspect the NIC interface that the trace traffic enters.
 * In Docker setting, the container is configured so that the network interfaces of the host is exposed to the container, enabling Suricata to inspect the same NIC interface as in bare metal setting.
 * In virtual machine setting, TBD.

### Special Treatments

 * To use streamlined test script, host user and sender must be
   able to run sudo without password prompt (`sudo visudo` and add `username ALL=(ALL) NOPASSWD: ALL`).

 * Use SSH authorized_keys to facilitate SSH login.

 * Because there is unavoidable overhead copying traffic from incoming NIC to VM NIC, VM will run even when testing Suricata in Docker and bare metal. This makes sure that the copy overhead appears in all three scenarios. However, Suricata in VM runs only when testing Suricata in VM.

## Experiments
