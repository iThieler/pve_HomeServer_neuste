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

pct exec $ctID -- bash -ci "wget -q https://github.com/MediaBrowser/Emby.Releases/releases/download/$( githubLatest \"MediaBrowser/Emby.Releases\" )/emby-server-deb_$( githubLatest \"MediaBrowser/Emby.Releases\" )_amd64.deb"
pct exec $ctID -- bash -ci "dpkg -i emby-server-deb_*_amd64.deb > /dev/null 2>&1"
pct exec $ctID -- bash -ci "rm emby-server-deb_*_amd64.deb"
pct exec $ctID -- bash -ci "systemctl start emby-server && systemctl enable emby-server > /dev/null 2>&1"

exit 0
