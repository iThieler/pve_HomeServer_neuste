lxc.apparmor.profile = unconfined     ### auf Host nach /etc/pve/lxc/$ctID.conf

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo 'deb https://download.mono-project.com/repo/ubuntu stable-focal main' | tee /etc/apt/sources.list.d/mono-official-stable.list

apt-get update && apt-get upgrade -y && apt-get dist-upgrade
apt-get install curl gnupg2 mediainfo cifs-utils mono-devel
curl -L -O $( curl -s https://api.github.com/repos/Radarr/Radarr/releases | grep linux.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4 )
tar -xvzf Radarr.*.linux.tar.gzecho 'deb https://download.mono-project.com/repo/ubuntu stable-focal main' | tee /etc/apt/sources.list.d/mono-official-stable.list
mv Radarr /opt
                    ### download config.xml Datei
                    ### download radarr.service

IPADRESSTOCHANGE    ### bearbeiten in config.xml
APIKEYTOCHANGE      ### bearbeiten in config.xml 32 Zeichen

systemctl start radarr && systemctl enable radarr
                    ### NAS einbinden
echo -e "[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\nIN HTTPS(ACCEPT) -source +pnetwork -log nolog\nIN HTTP(ACCEPT) -source +network -log nolog" >> ${clusterfileFW}
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw
