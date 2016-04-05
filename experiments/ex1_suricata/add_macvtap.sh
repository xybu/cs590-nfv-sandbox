#!/bin/bash

sudo ip link add link em2 name macvtap0 type macvtap mode passthru
sudo ip link set macvtap0 address 1a:46:0b:ca:bc:7b up
sudo ip link show macvtap0
