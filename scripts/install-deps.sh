#!/bin/bash

LC='\033[1;36m'         # light cyan
YE='\033[1;33m'         # yellow
NC='\033[0m'            # no color

curr_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# common packages
echo -e "${YE}Installing common packages...${NC}"
sudo apt update
sudo apt install -y cmake g++ git automake libtool libgc-dev bison flex libfl-dev libgmp-dev libboost-dev libboost-iostreams-dev libboost-graph-dev llvm pkg-config python python-scapy python-ipaddr python-ply tcpdump doxygen
sudo apt install -y autoconf autogen automake libtool python3.8 python3-pip
sudo pip3 install --upgrade setuptools
sudo pip3 install --pre scapy
sudo ln -s /usr/bin/python3.8 /usr/bin/python3
cd $curr_dir
echo

# repo url
repo[0]='protobuf'
repo[1]='protocolbuffers/'${repo[0]}'.git'

repo[2]='behavioral-model'
repo[3]='p4lang/'${repo[2]}'.git'

repo[4]='p4c'
repo[5]='p4lang/'${repo[4]}'.git'

total=${#repo[*]}
echo -e "${LC}Checking out repositories...${NC}"
echo

for (( i=0; i<${total}; i+=2 ));
do
  dir=${repo[$i]}
  trepo="https://github.com/${repo[$i+1]}"
  echo -e "${YE}Pulling ${repo[$i]}...${NC}"
  if cd $dir; then git pull; else git clone --recursive $trepo $dir; fi
  echo
done

echo -e "${LC}Installing dependencies...${NC}"
echo

# protobuf
echo -e "${YE}Installing ${repo[0]}...${NC}"
cd ${repo[0]}
git checkout v3.2.0
git submodule update --init --recursive
./autogen.sh
./configure
make
make check
sudo make install
sudo ldconfig
cd $curr_dir

# behavioral-model
echo -e "${YE}Installing ${repo[2]}...${NC}"
cd ${repo[2]}
./install_deps.sh
./autogen.sh
./configure
sudo make
sudo make install
sudo ldconfig
cd $curr_dir

# p4c
echo -e "${YE}Installing ${repo[4]}...${NC}"
cd ${repo[4]}
mkdir build
cd build
cmake ..
make -j2
make -j2 check
sudo make install
cd $curr_dir