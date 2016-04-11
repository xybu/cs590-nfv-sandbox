#!/bin/bash

sudo apt-get update && sudo apt-get upgrade
sudo apt-get -y install ack-grep build-essential cmake automake gcc g++ valgrind curl vim-tiny \
	gawk ssh libcurl4-openssl-dev openssl python-software-properties software-properties-common \
	python3-dev python-dev git mercurial

alias vi=vim

# No sudo password prompt.
MY_USERNAME=$USER
sudo echo "$MY_USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Configure Mercurial.
echo "[ui]" > ~/.hgrc
echo "username = Xiangyu Bu <xybu92@live.com>" >> ~/.hgrc
echo "verbose = True" >> ~/.hgrc

# Configure Git.
git config --global user.name "Xiangyu Bu"
git config --global user.email "xybu92@live.com"
git config --global core.editor vim

# Configure Python.
wget -O- https://bootstrap.pypa.io/get-pip.py | sudo python3
sudo pip install -U psutil
sudo pip install -U docker-py
sudo pip install -U spur

# Copy ssh key.
rsync -zrvpE bu1@cap07:/home/bu1/.ssh ~/
sudo ssh-keygen
sudo cp -r /home/bu1/.ssh /root/

# Mount extra hard disks.
sudo echo "/dev/sdb1	/scratch				  ext4    nodev,nosuid,acl        1       2" >> /etc/fstab
sudo echo "/dev/sdc1	/scratch2				  ext4    nodev,nosuid,acl        1       2" >> /etc/fstab

# Configure swappiness.
sudo echo "vm.swappiness = 5" >> /etc/sysctl.conf

# Configure em2.
sudo echo "" >> /etc/network/interfaces
sudo echo "auto em2" >> /etc/network/interfaces
sudo echo "iface em2 inet static" >> /etc/network/interfaces
sudo echo "address 192.168.0.1" >> /etc/network/interfaces
sudo echo "network 192.168.0.0" >> /etc/network/interfaces
sudo echo "netmask 255.255.255.0" >> /etc/network/interfaces
sudo echo "broadcast 192.168.0.255" >> /etc/network/interfaces

# Install docker.
curl -fsSL https://get.docker.com/gpg | sudo apt-key add -
curl -fsSL https://get.docker.com/ | sh
sudo usermod -aG docker $USER

# Fix cgroup issue.
sudo sed "s/GRUB_TIMEOUT=[0-9]*/GRUB_TIMEOUT=0/" /etc/default/grub /etc/default/grub >> /etc/default/grub
sudo sed "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cgroup_enable=memory swapaccount=1\"/" /etc/default/grub >> /etc/default/grub
sudo update-grub

# Install QEMU/KVM.
wget -O- https://raw.githubusercontent.com/xybu/cs590-nfv-sandbox/master/kvm/inst.sh | bash -s

# Install Suricata
# wget -O- https://raw.githubusercontent.com/xybu/cs590-nfv-sandbox/master/suricata/inst.sh | bash -s
