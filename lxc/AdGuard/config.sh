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

pct exec $ctID -- bash -ci "curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v > /dev/null 2>&1"
# Solve Problem with getting bind: address already in use error
pct exec $ctID -- bash -ci "if [ ! -d \"/etc/systemd/resolved.conf.d\" ]; then mkdir /etc/systemd/resolved.conf.d; fi"
pct exec $ctID -- bash -ci "echo -e \"[Resolve]\nDNS=127.0.0.1\nDNSStubListener=no\" >> /etc/systemd/resolved.conf.d/adguardhome.conf"
pct exec $ctID -- bash -ci "mv /etc/resolv.conf /etc/resolv.conf.backup"
pct exec $ctID -- bash -ci "ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf"
pct exec $ctID -- bash -ci "systemctl reload-or-restart systemd-resolved"
# copyfinal script
pct push $ctID "$script_path/lxc/$containername/make_conf.sh" "/root/make_conf.sh"

exit 0
