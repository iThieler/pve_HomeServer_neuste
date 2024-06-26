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
