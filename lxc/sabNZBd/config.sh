#!/bin/bash

pct exec $1 -- bash -ci "apt-get install software-properties-common"
pct exec $1 -- bash -ci "add-apt-repository multiverse"
pct exec $1 -- bash -ci "add-apt-repository universe"
pct exec $1 -- bash -ci "add-apt-repository ppa:jcfp/nobetas"
pct exec $1 -- bash -ci "add-apt-repository ppa:jcfp/sab-addons"
pct exec $1 -- bash -ci "apt-get install -y sabnzbdplus > /dev/null 2>&1"
pct exec $1 -- bash -ci "mkdir -p /media/Downloads/incomplete > /dev/null 2>&1"
pct exec $1 -- bash -ci "mkdir -p /media/Downloads/complete > /dev/null 2>&1"
pct exec $1 -- bash -ci "mkdir -p /media/Downloads/manualNZB > /dev/null 2>&1"
pct push $1 "$script_path/lxc/sabnzbd.ini" "/root/.sabnzbd/sabnzbd.ini"
pct exec $1 -- bash -ci "sed -i 's+IPADRESSTOCHANGE=+'"$2"'+' /root/.sabnzbd/sabnzbd.ini"
pct exec $1 -- bash -ci "sed -i 's+APIKEYTOCHANGE=+'"$( createAPIKey 32 )"'+' /root/.sabnzbd/sabnzbd.ini"
pct exec $1 -- bash -ci "sed -i 's+NZBAPIKEYTOCHANGE=+'"$( createAPIKey 32 )"'+' /root/.sabnzbd/sabnzbd.ini"
pct exec $1 -- bash -ci "sed -i 's+USER=+USER=root+' /etc/default/sabnzbdplus"
pct exec $1 -- bash -ci "sed -i 's+HOST=+HOST='"$2"'+' /etc/default/sabnzbdplus"
pct exec $1 -- bash -ci "sed -i 's+PORT=+PORT=80+' /etc/default/sabnzbdplus"
pct exec $1 -- bash -ci "systemctl start sabnzbdplus && systemctl enable sabnzbdplu"

exit 0

