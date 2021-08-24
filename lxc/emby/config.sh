#!/bin/bash

ctID=$1
ctIP=$2
ctRootpw="$3"
containername="$4"

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

# get latest gitHub Tag of embyMediaserver
ghTag=$(githubLatest MediaBrowser/Emby.Releases)

pct exec $ctID -- bash -ci "wget -q https://github.com/MediaBrowser/Emby.Releases/releases/download/${ghTag}/emby-server-deb_${ghTag}_amd64.deb"
pct exec $ctID -- bash -ci "dpkg -i emby-server-deb_${ghTag}_amd64.deb > /dev/null 2>&1"
pct exec $ctID -- bash -ci "rm emby-server-deb_${ghTag}_amd64.deb"
pct exec $ctID -- bash -ci "systemctl start emby-server && systemctl enable emby-server > /dev/null 2>&1"

exit 0
