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

# get latest gitHub Tag of embyMediaserver
ghTag=$(githubLatest Radarr/Radarr | sed 's#v##')

pct exec $ctID -- bash -ci "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo \"deb https://download.mono-project.com/repo/ubuntu stable-focal main\" | tee /etc/apt/sources.list.d/mono-official-stable.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y mono-devel mediainfo > /dev/null 2>&1"
pct exec $ctID -- bash -ci "wget -q https://github.com/Radarr/Radarr/releases/download/v${ghTag}/Radarr.master.${ghTag}.linux.tar.gz"
pct exec $ctID -- bash -ci "tar -xvzf Radarr.master.${ghTag}.linux.tar.gz > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mv Radarr /opt"
pct exec $ctID -- bash -ci "mkdir -p /media/Movies > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /root/.config/Radarr > /dev/null 2>&1"
pct push $ctID "$script_path/lxc/$containername/radarr.service" "/etc/systemd/system/radarr.service"
pct push $ctID "$script_path/lxc/$containername/config.xml" "/root/.config/Radarr/config.xml"
pct exec $ctID -- bash -ci "sed -i 's|IPADRESSTOCHANGE|'"$networkIP"'.'"$ctIP"'|' /root/.config/Radarr/config.xml"
pct exec $ctID -- bash -ci "sed -i 's|APIKEYTOCHANGE|'"$( generateAPIKey 32 )"'|' /root/.config/Radarr/config.xml"
pct exec $ctID -- bash -ci "systemctl start radarr && systemctl enable radarr > /dev/null 2>&1"

exit 0
