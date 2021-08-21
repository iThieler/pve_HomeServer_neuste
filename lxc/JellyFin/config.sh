#!/bin/bash

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

ctID=$1
ctRootpw=$2
ctIP=$(lxc-info $ctID -iH | grep $networkIP)
containername=$(pct list | grep $ctID | awk '{print $3}')

# Load container language file if not exist load english language
if [ -f "$script_path/lxc/$containername/language/$var_language.sh" ]; then
  source "$script_path/lxc/$containername/language/$var_language.sh"
else
  source "$script_path/lxc/$containername/language/en.sh"
fi

pct exec $ctID -- bash -ci "add-apt-repository universe"
pct exec $ctID -- bash -ci "wget -qO - https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | apt-key add - > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo \"deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/ubuntu focal main\" | tee /etc/apt/sources.list.d/jellyfin.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y jellyfin > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Movies/"
pct exec $ctID -- bash -ci "mkdir -p /media/Series/"
pct exec $ctID -- bash -ci "mkdir -p /media/Photos/"
pct exec $ctID -- bash -ci "systemctl start jellyfin && systemctl enable jellyfin > /dev/null 2>&1"

exit 0
