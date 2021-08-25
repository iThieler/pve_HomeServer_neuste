#!/bin/bash

ctID=$1
ctIP=$2
ctRootpw="$3"
containername="$4"

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

pct shutdown $ctID --timeout 5
sleep 10
pct set $ctID --memory 1024 --swap 1024
pct start $ctID
sleep 10
pct exec $ctID -- bash -ci "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo \"deb http://apt.sonarr.tv/ master main\" | tee /etc/apt/sources.list.d/sonarr.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo \"deb https://download.mono-project.com/repo/ubuntu stable-focal main\" | tee /etc/apt/sources.list.d/mono-official-stable.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y mono-devel mediainfo nzbdrone > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /media/Series/ > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /root/.config/NzbDrone/ > /dev/null 2>&1"
pct push $ctID "$script_path/lxc/$containername/sonarr.service" "/etc/systemd/system/sonarr.service"
pct push $ctID "$script_path/lxc/$containername/config.xml" "/root/.config/NzbDrone/config.xml"
pct exec $ctID -- bash -ci "sed -i 's#IPADRESSTOCHANGE#'"$networkIP"'.'"$ctIP"'#' /root/.config/NzbDrone/config.xml"
pct exec $ctID -- bash -ci "sed -i 's#APIKEYTOCHANGE#'"$( generateAPIKey 32 )"'#' /root/.config/NzbDrone/config.xml"
pct exec $ctID -- bash -ci "systemctl start sonarr && systemctl enable sonarr > /dev/null 2>&1"
pct shutdown $ctID --timeout 5
sleep 10
pct set $ctID --memory 256 --swap 256
pct start $ctID

exit 0
