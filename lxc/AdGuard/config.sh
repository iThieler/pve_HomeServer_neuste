#!/bin/bash

ctID=$1
ctIP=$2
ctRootpw="$3"
containername="$4"

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

pct exec $ctID -- bash -ci "curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v > /dev/null 2>&1"
pct push $ctID "$script_path/lxc/$containername/make_conf.sh" "/root/make_conf.sh"

exit 0
