#!/bin/bash

sudo apt-get install atop
wget -O- https://bootstrap.pypa.io/get-pip.py | sudo python3
sudo pip install -U docker-py
