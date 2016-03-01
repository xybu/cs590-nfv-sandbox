#!/bin/bash -xe

# Refer here: https://help.ubuntu.com/community/KVM/CreateGuests
# Or vmbuilder kvm ubuntu --help

HYPERVISOR=kvm
DISTRO=ubuntu
SUITE=trusty
MEMSIZE=1024 # In MiB.
NCPU=4
VMDOMAIN=vmdomain
VMHOSTNAME=vm
USERNAME=ubuntu
PASSWORD=ubuntu

SUDOERS_TMPL=/etc/vmbuilder/ubuntu/sudoers.tmpl
grep -q -e 'ubuntu' $SUDOERS_TMPL || sudo sed -i '$a ubuntu ALL=(ALL) NOPASSWD:ALL\n#includedir /etc/sudoers.d' $SUDOERS_TMPL

mkdir -p $DISTRO-$SUITE-amd64

# flavour : virtual, server, generic
# --firstboot PATH --firstlogin PATH --copy FILE --exec SCRIPT
sudo vmbuilder $HYPERVISOR $DISTRO --suite $SUITE --arch amd64 --flavour virtual  \
               --timezone America/Indiana/Indianapolis \
               --ssh-user-key ./config/id_rsa.pub    \
               --domain $VMDOMAIN --hostname $HOSTNAME --user $USERNAME --pass $PASSWORD \
               --rootsize 20480 --mem $MEMSIZE --cpus $NCPU              \
               --addpkg=linux-image-generic                              \
               --addpkg=openssh-server --addpkg=command-not-found        \
               --addpkg=iptables --addpkg=apt-transport-https            \
               --addpkg=avahi-daemon \
               --addpkg=acpid --addpkg=vim --debug -v                    \
               --libvirt qemu:///system \
               --dest ./$DISTRO-$SUITE-amd64/

