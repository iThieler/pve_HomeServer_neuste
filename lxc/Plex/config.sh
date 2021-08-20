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

pct exec $ctID -- bash -ci "wget -q https://downloads.plex.tv/plex-keys/PlexSign.key -O - | apt-key add - > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo \"deb https://downloads.plex.tv/repo/deb/ public main\" | tee /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y plexmediaserver > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Movies/ > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Series/ > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Photos/ > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl start plexmediaserver && systemctl enable plexmediaserver > /dev/null 2>&1"
pct exec $ctID -- bash -ci "sed -i 's+# deb+deb+' /etc/apt/sources.list.d/plexmediaserver.list"

exit 0
