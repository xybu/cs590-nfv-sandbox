#!/bin/bash

sudo apt-get install -y libglib2.0-dev qemu-kvm libvirt-bin bridge-utils virt-manager virt-top virt-what ubuntu-virt virtinst

# Create a SSH RSA key pair if missing.
if [ ! -f ~/.ssh/id_rsa.pub ] ; then
  echo -e '\033[91mSSH key missing. Prompt to generate...\033[0m'
  ssh-keygen
fi

# sudo apt-get install -y python-vm-builder
# Add ubuntu to sudoer
# SUDOERS_TMPL=/etc/vmbuilder/ubuntu/sudoers.tmpl
# grep -q -e 'ubuntu' $SUDOERS_TMPL || sudo sed -i '$a ubuntu ALL=(ALL) NOPASSWD:ALL\n#includedir /etc/sudoers.d' $SUDOERS_TMPL
