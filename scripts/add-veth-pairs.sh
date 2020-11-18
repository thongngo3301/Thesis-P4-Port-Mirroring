#!/bin/bash

LC='\033[1;36m'         # light cyan
NC='\033[0m'            # no color
echo -e "${LC}Reading config from ../config/veth-pairs.txt...${NC}"
echo

while IFS=' ' read -r col1 col2 || [ -n "$col1" ]
do
  vethA=veth$col1
  vethB=veth$col2

  sudo ip link add name $vethA type veth peer name $vethB
  sudo ip link set dev $vethA up
  sudo ip link set dev $vethB up
  sudo ip link set $vethA mtu 9500
  sudo ip link set $vethB mtu 9500
  sudo sysctl net.ipv6.conf.$vethA.disable_ipv6=1
  sudo sysctl net.ipv6.conf.$vethB.disable_ipv6=1
done < ../config/veth-pairs.txt