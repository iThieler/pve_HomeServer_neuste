#!/bin/bash

# Container Configuration
# $1=ctTemplate (ubuntu/debian/turnkey-openvpn) - $2=hostname - $3=ContainerRootPasswort - $4=hdd size - $5=cpu cores - $6=RAM Swap/2 - $7=unprivileged 0/1 - $8=features (keyctl=1,nesting=1,mount=cifs)
containerSetup ubuntu $ctName $ctRootpw 4 1 512 0 "mount=cifs;nfs"

# Comes from Mainscript - start.sh --> Function containerSetup
ctID=$?

# Software that must be installed on the container
# example - containerSoftware="docker.io docker-compose"
containerSoftware="gnupg ca-certificates mediainfo"

# Start Container, because Container stoped aftrer creation
pct start $ctID
sleep 10

# echo [INFO] The container "CONTAINERNAME" is prepared for configuration
echo -e "$info $lng_lxc \"$ctName\" $lng_installlxc1"

# Install the packages specified as containerSoftware
for package in $containerSoftware; do
  # echo [INFO] "PACKAGENAME" will be installed
  echo -e "$info \"$package\" $lng_installlxc"
  pct exec $nextCTID -- bash -c "apt-get install -y $package > /dev/null 2>&1"
done

# Execute commands on containers
# Install Mono
pct exec $ctID -- bash -ci "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo 'deb https://download.mono-project.com/repo/ubuntu stable-focal main' | tee /etc/apt/sources.list.d/mono-official-stable.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
echo -e "$info Nicht ungeduldig werden, das wird jetzt einige Zeit dauern ... :-)"
pct exec $ctID -- bash -ci "apt-get install -y mono-devel > /dev/null 2>&1"
systemctl disable binfmt-support
# Install sabnzbd
pct exec $ctID -- bash -ci "add-apt-repository multiverse > /dev/null 2>&1 && add-apt-repository universe > /dev/null 2>&1"
pct exec $ctID -- bash -ci "add-apt-repository -y ppa:jcfp/nobetas > /dev/null 2>&1 && add-apt-repository -y ppa:jcfp/sab-addons > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1 && apt-get dist-upgrade > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y sabnzbdplus > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl stop sabnzbdplus"
pct exec $ctID -- bash -ci "sed -i 's#USER=#USER=root#g' /etc/default/sabnzbdplus"
pct exec $ctID -- bash -ci "sed -i 's#HOST=#HOST=0.0.0.0#g' /etc/default/sabnzbdplus"
pct exec $ctID -- bash -ci "sed -i 's#PORT=#PORT=8080#g' /etc/default/sabnzbdplus"
pct exec $ctID -- bash -ci "systemctl start sabnzbdplus && systemctl enable sabnzbdplus > /dev/null 2>&1"
# Install Radarr
pct exec $ctID -- bash -ci "curl -L -O $( curl -s https://api.github.com/repos/Radarr/Radarr/releases | grep linux.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4 ) > /dev/null 2>&1"
pct exec $ctID -- bash -ci "tar -xvzf Radarr.*.linux.tar.gz > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mv Radarr /opt"
pct exec $ctID -- bash -ci "wget -qO /etc/systemd/system/radarr.service $rawGitHubURL/container/$ctName/radarr.service"
pct exec $ctID -- bash -ci "systemctl start radarr && systemctl enable radarr > /dev/null 2>&1"
# Install Sonarr
pct exec $ctID -- bash -ci "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo 'deb http://apt.sonarr.tv/ master main' | sudo tee /etc/apt/sources.list.d/sonarr.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y nzbdrone > /dev/null 2>&1"
pct exec $ctID -- bash -ci "wget -qO /etc/systemd/system/sonarr.service $rawGitHubURL/container/$ctName/sonarr.service"
pct exec $ctID -- bash -ci "systemctl start sonarr && systemctl enable sonarr > /dev/null 2>&1"

# If NAS exist in Network, bind to Container, only privileged and mount=cifs Feature is set
if [[ $nasexists == "y" ]]; then
  lxcMountNAS $ctID
  pct exec $ctID -- bash -ci "mkdir -p /media/Downloads/complete"
  pct exec $ctID -- bash -ci "mkdir -p /media/Downloads/incomplete"
fi

# Container description in the Proxmox web interface
pct set $ctID --description $'Shell Login\nBenutzer: root\nPasswort: '"$ctRootpw"$'\n\nWebGUI\nsabnzbd: http://'"$nextCTIP"$':8080/sabnzbd\nRadarr: http://'"$nextCTIP"$':7878\nSonarr: http://'"$nextCTIP"$':8989\n'

# echo [INFO] Create firewall rules for container "CONTAINERNAME"
echo -e "$info $lng_lxcfw \"$ctName\""

# Creates firewall rules for the container
# Create Firewallgroup - If a port should only be accessible from the local network - IN ACCEPT -source +network -p tcp -dport PORTNUMBER -log nolog
echo -e "[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\nIN ACCEPT -source +network -p tcp -dport 8080 -log nolog # Weboberfläche sabNZBd\nIN ACCEPT -source +network -p tcp -dport 7878 -log nolog # Weboberfläche Radarr\nIN ACCEPT -source +network -p tcp -dport 8989 -log nolog # Weboberfläche Sonarr\n\n" >> $clusterfileFW

# Allow Firewallgroup
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw

echo -e "[group downloadserver]\n\n" >> $fwcluster
