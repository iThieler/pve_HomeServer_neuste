#!/bin/bash

# Container Configuration
# $1=ctTemplate (ubuntu/debian/turnkey-openvpn) - $2=hostname - $3=ContainerRootPasswort - $4=hdd size - $5=cpu cores - $6=RAM Swap/2 - $7=unprivileged 0/1 - $8=features (keyctl=1,nesting=1,mount=cifs)
containerSetup ubuntu $ctName $ctRootpw 8 1 2048 0 "nesting=1,mount=nfs;cifs"

# Comes from Mainscript - start.sh --> Function containerSetup
ctID=$?

# Software that must be installed on the container
# example - containerSoftware="docker.io docker-compose"
containerSoftware="cifs-utils lsb-release apt-transport-https"

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
pct exec $ctID -- bash -ci "wget -qO - https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | apt-key add - > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo 'deb [arch=amd64] https://repo.jellyfin.org/ubuntu focal main' | tee /etc/apt/sources.list.d/jellyfin.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1 && apt-get install -y jellyfin > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl start jellyfin && systemctl enable jellyfin > /dev/null 2>&1"
#if [ $(ls -la /dev/dri/card0 | grep -c video) -eq 1 ]; then
#  whiptail --yesno --backtitle "SmartHome-IoT.net - JellyFin" --title "Grafikkarte" "In deinem System wurde eine Grafikkarte erkannt. Diese kann in JellyFin eingebunden werden um das Transkodieren von Videodateien zu beschleunigen und zu verbessern. Soll die Grafikkarte in JellyFin eingebunden werden?" ${r} ${c}
#  exitstatus=$?
#  if [ $exitstatus = 0 ]; then
#    gpuid=$(ls -la /dev/dri | grep video | head -n1 | awk '{print $5}' | cut -d, -f1)
#    renderid=$(ls -la /dev/dri | grep render | head -n1 | awk '{print $10}' | cut -d'r' -f3)
#    echo "lxc.cgroup.devices.allow: c $gpuid:* rwm" >> /etc/pve/lxc/$ctID.conf
#    echo "lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
#    echo "lxc.mount.entry: /dev/dri/render$renderid dev/dri/render$renderid none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
#  fi
#fi
if [[ $nasexists == "y" ]]; then
  lxcMountNAS $ctID
  pct exec $ctID -- bash -ci "mkdir -p /media/Movies"
  pct exec $ctID -- bash -ci "mkdir -p /media/Series"
  pct exec $ctID -- bash -ci "mkdir -p /media/Photos"
fi

# Container description in the Proxmox web interface
pct set $ctID --description $'Shell Login\nBenutzer: root\nPasswort: '"$ctRootpw"$'\n\nWebGUI\nAdresse: http://'"$nextCTIP"$':8096'

# echo [INFO] Create firewall rules for container "CONTAINERNAME"
echo -e "$info $lng_lxcfw \"$ctName\""

# Creates firewall rules for the container
# Create Firewallgroup - If a port should only be accessible from the local network - IN ACCEPT -source +network -p tcp -dport PORTNUMBER -log nolog
echo -e "[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\nIN ACCEPT -p tcp -dport 8920 -log nolog # Weboberfläche HTTPs\nIN ACCEPT -source +network -p tcp -dport 8096 -log nolog # Weboberfläche\nIN ACCEPT -source +network -p udp -dport 7359 -log nolog # Client Discovery\nIN ACCEPT -source +network -p udp -dport 1900 -log nolog # Service Discovery\n\n" >> $fwcluster

# Allow Firewallgroup
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw


