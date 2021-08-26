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

pct exec $ctID -- bash -ci "add-apt-repository multiverse > /dev/null 2>&1"
pct exec $ctID -- bash -ci "add-apt-repository universe > /dev/null 2>&1"
pct exec $ctID -- bash -ci "add-apt-repository ppa:jcfp/nobetas > /dev/null 2>&1"
pct exec $ctID -- bash -ci "add-apt-repository ppa:jcfp/sab-addons > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y sabnzbdplus > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Downloads/incomplete > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Downloads/complete > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Downloads/manualNZB > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /root/.sabnzbd > /dev/null 2>&1"
pct exec $ctID -- bash -ci "if [ -f /root/.sabnzbd/sabnzbd.ini ]; then rm /root/.sabnzbd/sabnzbd.ini; fi"
pct push $ctID "$script_path/lxc/$containername/sabnzbd.ini" "/root/.sabnzbd/sabnzbd.ini"
pct exec $ctID -- bash -ci "sed -i 's+IPADRESSTOCHANGE=+'"$networkIP"'.'"$ctIP"'+' /root/.sabnzbd/sabnzbd.ini"
pct exec $ctID -- bash -ci "sed -i 's+APIKEYTOCHANGE=+'"$( generateAPIKey 32 )"'+' /root/.sabnzbd/sabnzbd.ini"
pct exec $ctID -- bash -ci "sed -i 's+NZBAPIKEYTOCHANGE=+'"$( generateAPIKey 32 )"'+' /root/.sabnzbd/sabnzbd.ini"
pct exec $ctID -- bash -ci "sed -i 's+USER=+USER=root+' /etc/default/sabnzbdplus"
pct exec $ctID -- bash -ci "sed -i 's+HOST=+HOST='"$networkIP"'.'"$ctIP"'+' /etc/default/sabnzbdplus"
pct exec $ctID -- bash -ci "sed -i 's+PORT=+PORT=80+' /etc/default/sabnzbdplus"
pct exec $ctID -- bash -ci "systemctl start sabnzbdplus && systemctl enable sabnzbdplus > /dev/null 2>&1"

exit 0
