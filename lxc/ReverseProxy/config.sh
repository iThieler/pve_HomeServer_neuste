#!/bin/bash

ctID=$1
ctIP=$2
ctRootpw="$3"
containername="$4"
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

#https://www.youtube.com/watch?v=b5JVFt0wd4Y - https://www.youtube.com/watch?v=h4u5g2K-6xs
pct exec $ctID -- bash -ci "apt-get install -y docker.io docker-compose > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl start docker && systemctl enable docker > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /root/npm/ > /dev/null 2>&1"
pct push $ctID "$script_path/lxc/ReverseProxy/docker-compose.yml" "/root/npm/docker-compose.yml"
pct exec $ctID -- bash -ci "sed -i 's|ROOTPASSWORDTOCHANGE|'"$ctRootpw"'|g' /root/npm/docker-compose.yml"
pct exec $ctID -- bash -ci "cd /root/npm && docker-compose up -d --quiet-pull > /dev/null 2>&1"

exit 0
