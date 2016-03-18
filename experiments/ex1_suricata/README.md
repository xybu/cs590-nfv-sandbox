Experiment 1
============

This experiment intends to compare performance of Suricata running on three
different environments:

 - directly on host (Ubuntu 14.04.4 bare metal)
 - inside Docker container (Ubuntu 14.04.4 Container)
 - inside QEMU/KVM virtual machine (Ubuntu 14.04.4 VM, ubuntu3)

by replaying different TCP pcap traces inside a guest VM (Ubuntu 14.04.4, ubuntu1).

The guest VM to replay traffic is on the same physical machine as Suricata / Docker /  ubuntu3 VM.
