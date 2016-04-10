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
cd suricata-3.0.1

./configure --enable-nfqueue --enable-unittests --enable-profiling --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make
sudo make install-full
sudo ldconfig

# Make log dir
sudo mkdir -p /var/log/suricata

# Get some rule set from Internet.
# cd /tmp
# wget http://rules.emergingthreats.net/open/suricata/emerging.rules.tar.gz
# sudo tar xvf emerging.rules.tar.gz
# sudo cp -vfpr ./rules/* /etc/suricata/rules/
# sudo wget --no-parent -l1 -r --no-directories -P /etc/suricata/rules/ https://rules.emergingthreats.net/open/suricata/rules/

sudo chmod u+s /usr/bin/suricata
