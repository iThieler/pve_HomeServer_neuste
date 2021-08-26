#!/bin/bash

ctID=$1
ctIP=$2
ctRootpw="$3"
containername="$4"
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"


pct exec $ctID -- bash -ci "wget -q https://downloads.plex.tv/plex-media-server-new/1.24.1.4931-1a38e63c6/debian/plexmediaserver_1.24.1.4931-1a38e63c6_amd64.deb && dpkg -i plex* > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl start plexmediaserver && systemctl enable plexmediaserver > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo \"deb https://downloads.plex.tv/repo/deb/ public main\" > /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "wget -q https://downloads.plex.tv/plex-keys/PlexSign.key -O - | apt-key add - > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Movies/ > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Series/ > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Photos/ > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1"

exit 0
