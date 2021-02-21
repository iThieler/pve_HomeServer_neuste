lxc.apparmor.profile = unconfined     ### auf Host nach /etc/pve/lxc/$ctID.conf

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493
echo 'deb http://apt.sonarr.tv/ master main' | sudo tee /etc/apt/sources.list.d/sonarr.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo 'deb https://download.mono-project.com/repo/ubuntu stable-focal main' | tee /etc/apt/sources.list.d/mono-official-stable.list


apt-get update && apt-get upgrade -y && apt-get dist-upgrade
apt-get install curl gnupg2 mediainfo cifs-utils mono-devel nzbdrone
                    ### download config.xml Datei
                    ### download sonarr.service

IPADRESSTOCHANGE    ### bearbeiten in config.xml
APIKEYTOCHANGE      ### bearbeiten in config.xml 32 Zeichen

systemctl start sonarr && systemctl enable sonarr
                    ### NAS einbinden
echo -e "[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\nIN HTTPS(ACCEPT) -source +pnetwork -log nolog\nIN HTTP(ACCEPT) -source +network -log nolog" >> ${clusterfileFW}
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw
