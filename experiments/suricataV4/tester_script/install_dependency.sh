#!/bin/bash

sudo apt-get install python-dev python3-dev
wget -O- https://bootstrap.pypa.io/get-pip.py | sudo python3

which docker > /dev/null
if [ "$?" -eq "0" ] ; then
	sudo pip install -U docker-py
fi

sudo pip install -U psutil
sudo pip install -U spur
