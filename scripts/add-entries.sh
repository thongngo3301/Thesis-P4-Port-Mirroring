LC='\033[1;36m'         # light cyan
YE='\033[1;33m'         # yellow
NC='\033[0m'            # no color
echo -e "${LC}Reading config from ../config/entries.txt...${NC}"
echo

echo -e "${LC}Useful commands:
${YE}show_tables
${YE}table_info <TABLE_NAME>
${YE}table_add <TABLE_NAME> <ACTION>
${YE}table_dump <TABLE_NAME>
${NC}"

simple_switch_CLI < ../config/entries.txt
simple_switch_CLI