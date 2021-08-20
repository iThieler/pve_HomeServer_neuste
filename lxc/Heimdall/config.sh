#!/bin/bash

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"
source "$script_path/lxc/$containername/language/$var_language.sh"

ctID=$1
ctRootpw=$2
ctIP=$(lxc-info $ctID -iH | grep $networkIP)
containername=$(pct list | grep 100 | awk '{print $3}')

pct exec $ctID -- bash -ci "apt-get install -y docker.io docker-compose > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl start docker && systemctl enable docker > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /root/heimdall/"
pct push $ctID "$script_path/lxc/heimdall/docker-compose.yml" "/root/heimdall/docker-compose.yml"
pct exec $ctID -- bash -ci "sed -i 's#TIMEZONETOCHANGE#'"$timezone"'#' /root/heimdall/docker-compose.yml"
pct exec $ctID -- bash -ci "cd /root/heimdall && docker-compose up -d --quiet-pull > /dev/null 2>&1"

exit 0
