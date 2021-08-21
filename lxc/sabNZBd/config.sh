#!/bin/bash

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

ctID=$1
ctRootpw=$2
ctIP=$(lxc-info $ctID -iH | grep $networkIP)
containername=$(pct list | grep $ctID | awk '{print $3}')

source "$script_path/lxc/$containername/language/$var_language.sh"

pct exec $ctID -- bash -ci "add-apt-repository multiverse > /dev/null 2>&1"
pct exec $ctID -- bash -ci "add-apt-repository universe > /dev/null 2>&1"
pct exec $ctID -- bash -ci "add-apt-repository ppa:jcfp/nobetas > /dev/null 2>&1"
pct exec $ctID -- bash -ci "add-apt-repository ppa:jcfp/sab-addons > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y sabnzbdplus > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Downloads/incomplete > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Downloads/complete > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Downloads/manualNZB > /dev/null 2>&1"
pct push $ctID "$script_path/lxc/$containername/sabnzbd.ini" "/root/.sabnzbd/sabnzbd.ini"
pct exec $ctID -- bash -ci "sed -i 's+IPADRESSTOCHANGE=+'"$ctIP"'+' /root/.sabnzbd/sabnzbd.ini"
pct exec $ctID -- bash -ci "sed -i 's+APIKEYTOCHANGE=+'"$( generateAPIKey 32 )"'+' /root/.sabnzbd/sabnzbd.ini"
pct exec $ctID -- bash -ci "sed -i 's+NZBAPIKEYTOCHANGE=+'"$( generateAPIKey 32 )"'+' /root/.sabnzbd/sabnzbd.ini"
pct exec $ctID -- bash -ci "sed -i 's+USER=+USER=root+' /etc/default/sabnzbdplus"
pct exec $ctID -- bash -ci "sed -i 's+HOST=+HOST='"$ctIP"'+' /etc/default/sabnzbdplus"
pct exec $ctID -- bash -ci "sed -i 's+PORT=+PORT=80+' /etc/default/sabnzbdplus"
pct exec $ctID -- bash -ci "systemctl start sabnzbdplus && systemctl enable sabnzbdplu"

exit 0

