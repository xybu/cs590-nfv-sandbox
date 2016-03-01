#!/bin/bash

# Install packages.
sudo apt-get install qemu-kvm libvirt-bin bridge-utils virt-manager virtinst python-vm-builder

# Generate a RSA key for SSHing into the VMs.
sudo mkdir config
ssh-keygen -t rsa -P "" -f ./config/id_rsa
