#!/bin/bash

# Container Configuration
# $1=ctTemplate (ubuntu/debian/turnkey-openvpn) - $2=hostname - $3=ContainerRootPasswort - $4=hdd size - $5=cpu cores - $6=RAM Swap/2 - $7=unprivileged 0/1 - $8=features (keyctl=1,nesting=1,mount=cifs)
lxcSetup ubuntu $ctName $ctRootpw 8 1 512 1 "keyctl=1,nesting=1"

# Comes from Mainscript - start.sh --> Function lxcSetup
ctID=$?

# Software that must be installed on the container
# example - containerSoftware="docker.io docker-compose"
containerSoftware=""

# Start Container, because Container stoped aftrer creation
pct start $ctID
sleep 10

# echo [INFO] The container "CONTAINERNAME" is prepared for configuration
echo -e "XXX\n0\n$lng_lxc_create_text_software_install\nXXX"

# Install the packages specified as containerSoftware
for package in $containerSoftware; do
  # echo [INFO] "PACKAGENAME" will be installed
  pct exec $nextCTID -- bash -c "apt-get install -y $package > /dev/null 2>&1"
done

# Execute commands on containers
echo -e "XXX\n33\n$lng_lxc_create_text_package_install - \"Mono\"\nXXX"
pct exec $ctID -- bash -ci ""

# If NAS exist in Network, bind to Container, only privileged and mount=cifs Feature is set
if [[ $nasexists == "y" ]]; then
  echo -e "XXX\n92\n$lng_lxc_create_text_nas\nXXX"
  lxcMountNAS $ctID
  pct exec $ctID -- bash -ci "mkdir -p /media/FOLDERNAMEYOUWISH"
fi

# Container description in the Proxmox web interface
pct set $ctID --description $'Shell Login\nBenutzer: root\nPasswort: '"$ctRootpw"$'\n\nWebGUI\nAdresse: http://'"$nextCTIP"$':81\nBenutzer: admin@example.com\nPasswort: changeme'

# echo [INFO] Create firewall rules for container "CONTAINERNAME"
echo -e "XXX\n99\n$lng_lxc_create_text_firewall\nXXX"

# Creates firewall rules for the container
# Create Firewallgroup - If a port should only be accessible from the local network - IN ACCEPT -source +network -p tcp -dport PORTNUMBER -log nolog
echo -e "[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\nIN HTTPS(ACCEPT) -log nolog\nIN HTTP(ACCEPT) -log nolog\nIN ACCEPT -source +network -p tcp -dport 81 -log nolog # Weboberfläche\n\n" >> $clusterfileFW

# Allow Firewallgroup
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw
