LC='\033[1;36m'         # light cyan
YE='\033[1;33m'         # yellow
NC='\033[0m'            # no color
echo -e "${LC}Reading config from ../config/mc-commands.txt...${NC}"
echo

echo -e "${LC}Useful commands:
${YE}mc_mgrp_create <GROUP_ID>
${YE}mc_node_create <RID> <SPACE-SEPARATED PORT LIST>
${YE}mc_node_associate <GROUP_ID> <RID>
${NC}"

simple_switch_CLI < ../config/mc-commands.txt
simple_switch_CLI