#!/bin/bash

LC='\033[1;36m'         # light cyan
NC='\033[0m'            # no color

curr_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
project_dir="$(dirname "$curr_dir")"

# compile
cd $project_dir
echo -e "${LC}Compiling P4 switch...${NC}"
echo

p4c -b bmv2 pm_switch_test.p4 -o pm_switch.bmv2

# start
cd $project_dir
echo -e "${LC}Starting P4 switch...${NC}"
echo

sudo simple_switch --interface 1@ens39 \
                  --interface 2@ens38 \
                  --interface 3@ens40 \
                  pm_switch.bmv2/pm_switch_test.json