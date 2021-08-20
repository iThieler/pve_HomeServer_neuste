#!/bin/bash

ctID=$1
ctRootpw=$2
ctIP=$(lxc-info $ctID -iH | grep $networkIP)
containername=$(pct list | grep 100 | awk '{print $3}')

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"
source "$script_path/lxc/$containername/language/$var_language.sh"

pct exec $ctID -- bash -ci "apt-get install -y docker.io docker-compose > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl start docker && systemctl enable docker > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /root/npm/ > /dev/null 2>&1"
pct push $ctID "$script_path/lxc/ReverseProxy/docker-compose.yml" "/root/npm/docker-compose.yml"
pct exec $ctID -- bash -ci "sed -i 's#ROOTPASSWORDTOCHANGE#'"$ctRootpw"'#g' /root/npm/docker-compose.yml"
pct exec $ctID -- bash -ci "cd /root/npm && docker-compose up -d --quiet-pull > /dev/null 2>&1"

exit 0
