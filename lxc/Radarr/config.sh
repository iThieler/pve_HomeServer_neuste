#!/bin/bash

pct exec $1 -- bash -ci "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
pct exec $1 -- bash -ci "echo \"deb https://download.mono-project.com/repo/ubuntu stable-focal main\" | tee /etc/apt/sources.list.d/mono-official-stable.list"
pct exec $1 -- bash -ci "apt-get install -y mono-devel mediainfo > /dev/null 2>&1"
pct exec $1 -- bash -ci "wget -q https://github.com/Radarr/Radarr/releases/download/$( getLatestGit \"Radarr/Radarr\" )/Radarr.master.$( getLatestGit \"Radarr/Radarr\" ).linux.tar.gz"
pct exec $1 -- bash -ci "tar -xvzf Radarr.*.linux.tar.gz"
pct exec $1 -- bash -ci "mv Radarr /opt"
pct exec $1 -- bash -ci "mkdir -p /media/Movies > /dev/null 2>&1"
pct push $1 "$script_path/lxc/Radarr/radarr.service" "/etc/systemd/system/radarr.service"
pct push $1 "$script_path/lxc/Radarr/config.xml" "/root/.config/Radarr/config.xml"
pct exec $1 -- bash -ci "sed -i 's#IPADRESSTOCHANGE#'"$2"'#' /root/.config/Radarr/config.xml"
pct exec $1 -- bash -ci "sed -i 's#APIKEYTOCHANGE#'"$( createAPIKey 32 )"'#' /root/.config/Radarr/config.xml"
pct exec $1 -- bash -ci "systemctl start radarr && systemctl enable radarr"

exit 0
