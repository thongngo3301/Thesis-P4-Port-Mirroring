#!/bin/bash

vethA=veth$1
vethB=veth$2

sudo ip link add name $vethA type veth peer name $vethB
sudo ip link set dev $vethA up
sudo ip link set dev $vethB up
sudo ip link set $vethA mtu 9500
sudo ip link set $vethB mtu 9500
sudo sysctl net.ipv6.conf.$vethA.disable_ipv6=1
sudo sysctl net.ipv6.conf.$vethB.disable_ipv6=1