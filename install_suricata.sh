#!/bin/bash

# According to
# https://redmine.openinfosecfoundation.org/projects/suricata/wiki/Ubuntu_Installation

sudo apt-get -y install libpcre3 libpcre3-dbg libpcre3-dev \
build-essential autoconf automake libtool libpcap-dev libnet1-dev \
libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 \
make libmagic-dev libjansson-dev libjansson4

sudo apt-get -y install libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev libnfnetlink0

cd /tmp
wget http://downloads.suricata-ids.org/suricata-current.tar.gz
tar xvf suricata-current.tar.gz
cd suricata-3.0

./configure --enable-nfqueue --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make
sudo make install-full
sudo ldconfig
