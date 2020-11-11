#!/bin/bash

THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source $THIS_DIR/env.sh

P4C_BM_SCRIPT=$P4C_BM_PATH/p4c_bm/__main__.py

SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch
# SWITCH_PATH=$THIS_DIR/behavioral-model

CLI_PATH=$THIS_DIR/simple_switch_CLI.py

$P4C_BM_SCRIPT p4src/switch.p4 --json switch.json

sudo PYTHONPATH=$PYTHONPATH:$BMV2_PATH/mininet/ python topo.py \
    --behavioral-exe $SWITCH_PATH \
    --json switch.json \
    --cli $CLI_PATH \
    --mode l2
