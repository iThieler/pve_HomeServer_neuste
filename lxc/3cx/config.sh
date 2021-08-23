#!/bin/bash

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

ctID=$1
ctRootpw=$2
ctIP=$(lxc-info $ctID -iH | grep $networkIP)
containername=$(pct list | grep $ctID | awk '{print $3}')

echo -e "3cx Config source \"$script_path/lxc/$containername/language/$var_language.sh\""
pct exec $ctID -- bash -ci "wget -qO - http://downloads-global.3cx.com/downloads/3cxpbx/public.key | apt-key add - > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo \"deb http://downloads-global.3cx.com/downloads/debian stretch main\" | tee /etc/apt/sources.list.d/3cxpbx.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y iperf libicu57 libicu57 dphys-swapfile > /dev/null 2>&1"

exit 0
