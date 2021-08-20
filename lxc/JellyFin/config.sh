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

pct exec $ctID -- bash -ci "add-apt-repository universe"
pct exec $ctID -- bash -ci "wget -O - https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | apt-key add - > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo \"deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/ubuntu $( lsb_release -c -s ) main\" | tee /etc/apt/sources.list.d/jellyfin.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y jellyfin > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Movies/"
pct exec $ctID -- bash -ci "mkdir -p /media/Series/"
pct exec $ctID -- bash -ci "mkdir -p /media/Photos/"
pct exec $ctID -- bash -ci "systemctl start jellyfin && systemctl enable jellyfin > /dev/null 2>&1"

exit 0
