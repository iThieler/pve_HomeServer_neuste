#!/bin/bash

Commands="pct exec $ctID -- bash -ci \"apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF\"
          pct exec $ctID -- bash -ci \"echo \"deb https://download.mono-project.com/repo/ubuntu stable-focal main\" | tee /etc/apt/sources.list.d/mono-official-stable.list\"
          pct exec $ctID -- bash -ci \"apt-get install -y mono-devel mediainfo > /dev/null 2>&1\"
          pct exec $ctID -- bash -ci \"wget -q https://github.com/Radarr/Radarr/releases/download/$( getLatestGit \"Radarr/Radarr\" )/Radarr.master.$( getLatestGit \"Radarr/Radarr\" ).linux.tar.gz\"
          pct exec $ctID -- bash -ci \"tar -xvzf Radarr.*.linux.tar.gz\"
          pct exec $ctID -- bash -ci \"mv Radarr /opt\"
          pct exec $ctID -- bash -ci \"mkdir -p /media/Movies > /dev/null 2>&1\"
          pct exec $ctID -- bash -ci \"wget -qO /etc/systemd/system/radarr.service $repoUrlLXC/$hostname/radarr.service\"
          pct push $ctIP \"$script_path/lxc/Radarr/config.xml\" \"/root/.config/Radarr/config.xml\"
          pct exec $ctID -- bash -ci \"sed -i 's#IPADRESSTOCHANGE#'"$ctIP"'#' /root/.config/Radarr/config.xml\"
          pct exec $ctID -- bash -ci \"sed -i 's#APIKEYTOCHANGE#'"$( createAPIKey 32 )"'#' /root/.config/Radarr/config.xml\"
          pct exec $ctID -- bash -ci \"systemctl start radarr && systemctl enable radarr\""
