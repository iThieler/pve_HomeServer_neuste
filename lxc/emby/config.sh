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

# get latest gitHub Tag of embyMediaserver
ghTag=$(githubLatest MediaBrowser/Emby.Releases)

pct exec $ctID -- bash -ci "wget -q https://github.com/MediaBrowser/Emby.Releases/releases/download/${ghTag}/emby-server-deb_${ghTag}_amd64.deb"
pct exec $ctID -- bash -ci "dpkg -i emby-server-deb_${ghTag}_amd64.deb > /dev/null 2>&1"
pct exec $ctID -- bash -ci "rm emby-server-deb_${ghTag}_amd64.deb"
pct exec $ctID -- bash -ci "systemctl start emby-server && systemctl enable emby-server > /dev/null 2>&1"

exit 0
