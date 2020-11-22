#!/bin/bash

LC='\033[1;36m'         # light cyan
NC='\033[0m'            # no color

curr_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
project_dir="$(dirname "$curr_dir")"

# compile
cd $project_dir
echo -e "${LC}Compiling P4 switch...${NC}"
echo

p4c -b bmv2 pm_switch.p4 -o pm_switch.bmv2

# start
cd $project_dir
echo -e "${LC}Starting P4 switch...${NC}"
echo

veth_id_arr=()
while IFS=' ' read -r col1 col2 || [ -n "$col1" ]
do
  # col2 is veth id of veth connected to switch
  veth_id_arr+=("${col2}")
done < config/veth-pairs.txt

sudo simple_switch --interface 1@veth${veth_id_arr[0]} \
                  --interface 2@veth${veth_id_arr[1]} \
                  --interface 3@veth${veth_id_arr[2]} \
                  --interface 4@veth${veth_id_arr[3]} \
                  --interface 5@veth${veth_id_arr[4]} \
                  pm_switch.bmv2/pm_switch.json