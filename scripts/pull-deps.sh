#!/bin/bash

curr_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# repo url
repo[0]='protobuf'
repo[1]='protocolbuffers/'${repo[0]}'.git'

repo[2]='behavioral-model'
repo[3]='p4lang/'${repo[2]}'.git'

repo[4]='p4c'
repo[5]='p4lang/'${repo[4]}'.git'

total=${#repo[*]}
echo "Checking out repositories..."
echo

for (( i=0; i<${total}; i+=2 ));
do
  dir=${repo[$i]}
  trepo="https://github.com/${repo[$i+1]}"
  echo "Checking out ${repo[$i]}"...
  if cd $dir; then git pull; else git clone --recursive $trepo $dir; fi
  echo
done