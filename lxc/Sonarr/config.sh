#!/bin/bash

pct exec $1 -- bash -ci "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493"
pct exec $1 -- bash -ci "echo \"deb http://apt.sonarr.tv/ master main\" | tee /etc/apt/sources.list.d/sonarr.list"
pct exec $1 -- bash -ci "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
pct exec $1 -- bash -ci "echo \"deb https://download.mono-project.com/repo/ubuntu stable-focal main\" | tee /etc/apt/sources.list.d/mono-official-stable.list"
pct exec $1 -- bash -ci "apt-get install -y mono-devel mediainfo nzbdrone > /dev/null 2>&1"
pct exec $1 -- bash -ci "mkdir -p /media/Series/ > /dev/null 2>&1"
pct push $1 "$script_path/lxc/Sonarr/sonarr.service" "/etc/systemd/system/sonarr.service"
pct push $1 "$script_path/lxc/Sonarr/config.xml" "/root/.config/NzbDrone/config.xml"
pct exec $1 -- bash -ci "sed -i 's#IPADRESSTOCHANGE#'"$2"'#' /root/.config/NzbDrone/config.xml"
pct exec $1 -- bash -ci "sed -i 's#APIKEYTOCHANGE#'"$( createAPIKey 32 )"'#' /root/.config/NzbDrone/config.xml"
pct exec $1 -- bash -ci "systemctl start sonarr && systemctl enable sonarr"

exit 0
