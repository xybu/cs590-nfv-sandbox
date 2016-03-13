#!/bin/bash

# Add GetDeb repo.
wget -q -O - http://archive.getdeb.net/getdeb-archive.key | sudo apt-key add -
sudo sh -c 'echo "deb http://archive.getdeb.net/ubuntu trusty-getdeb apps" >> /etc/apt/sources.list.d/getdeb.list'

# Install packages.
sudo apt-get install qemu-kvm libvirt-bin bridge-utils virt-manager virt-top virt-what ubuntu-virt
sudo apt-get install -y virtinst
sudo apt-get install -y python-vm-builder

# Create a SSH RSA key pair if missing.
if [ ! -f ~/.ssh/id_rsa.pub ] ; then
  echo -e '\033[91mSSH key missing. Prompt to generate...\033[0m'
  ssh-keygen
fi

# Add ubuntu to sudoer
SUDOERS_TMPL=/etc/vmbuilder/ubuntu/sudoers.tmpl
grep -q -e 'ubuntu' $SUDOERS_TMPL || sudo sed -i '$a ubuntu ALL=(ALL) NOPASSWD:ALL\n#includedir /etc/sudoers.d' $SUDOERS_TMPL
