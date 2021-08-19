#!/bin/bash

Commands="pct exec $ctID -- bash -ci \"apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493\"
          pct exec $ctID -- bash -ci \"echo \"deb http://apt.sonarr.tv/ master main\" | tee /etc/apt/sources.list.d/sonarr.list\"
          pct exec $ctID -- bash -ci \"apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF\"
          pct exec $ctID -- bash -ci \"echo \"deb https://download.mono-project.com/repo/ubuntu stable-focal main\" | tee /etc/apt/sources.list.d/mono-official-stable.list\"
          pct exec $ctID -- bash -ci \"apt-get install -y mono-devel mediainfo nzbdrone > /dev/null 2>&1\"
          pct exec $ctID -- bash -ci \"mkdir -p /media/Series/ > /dev/null 2>&1\"
          pct push $ctIP \"$script_path/lxc/Sonarr/sonarr.service\" /etc/systemd/system/sonarr.service\"
          pct push $ctIP \"$script_path/lxc/Sonarr/config.xml\" \"/root/.config/NzbDrone/config.xml\"
          pct exec $ctID -- bash -ci \"sed -i 's#IPADRESSTOCHANGE#'"$ctIP"'#' /root/.config/NzbDrone/config.xml\"
          pct exec $ctID -- bash -ci \"sed -i 's#APIKEYTOCHANGE#'"$( createAPIKey 32 )"'#' /root/.config/NzbDrone/config.xml\"
          pct exec $ctID -- bash -ci \"systemctl start sonarr && systemctl enable sonarr\""
