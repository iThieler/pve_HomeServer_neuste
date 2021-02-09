#!/bin/bash

# Container Configuration
# $1=ctTemplate (ubuntu/debian/turnkey-openvpn) - $2=hostname - $3=ContainerRootPasswort - $4=hdd size - $5=cpu cores - $6=RAM Swap/2 - $7=unprivileged 0/1 - $8=features (keyctl=1,nesting=1,mount=cifs)
containerSetup debian $ctName $ctRootpw 8 1 1024 0 "mount=cifs;nfs"

# Comes from Mainscript - start.sh --> Function containerSetup
ctID=$?

# Software that must be installed on the container
# example - containerSoftware="docker.io docker-compose"
containerSoftware="apt-transport-https"

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
pct exec $ctID -- bash -ci "wget -qO - http://downloads-global.3cx.com/downloads/3cxpbx/public.key | apt-key add - > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo ""deb http://downloads-global.3cx.com/downloads/debian stretch main"" | tee /etc/apt/sources.list.d/3cxpbx.list > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
pct exec $ctID -- bash -ci "wget -qO /root/libicu57_57.1-6+deb9u4_amd64.deb http://ftp.de.debian.org/debian/pool/main/i/icu/libicu57_57.1-6+deb9u4_amd64.deb"
pct exec $ctID -- bash -ci "apt-get -y install dphys-swapfile > /dev/null 2>&1"
pct exec $ctID -- bash -ci "dpkg -i /root/libicu57_57.1-6+deb9u4_amd64.deb > /dev/null 2>&1"
pct exec $ctID -- bash -ci "rm /root/libicu57_57.1-6+deb9u4_amd64.deb"

#PermitRootLogin prohibit-password+PermitRootLogin yes
#/etc/init.d/ssh restart > /dev/null 2>&1

#pct exec $ctID -- bash -ci "apt-get -y install 3cxpbx"

# Container description in the Proxmox web interface
pct set $ctID --description $'Shell Login\nBenutzer: root\nPasswort: '"$ctRootpw"$'\n\nAdministrations WebGUI\nAdresse: https://'"$nextCTIP"$':5001\nBenutzer: \nPasswort: \n\nBenutzer WebGUI\nAdresse: https://'"$nextCTIP"$':5001/webclient\nBenutzer: Nebenstellennummer \nPasswort: per E-Mail erhalten\n\nWebGUI Ersteinrichtung\nAdresse: http://'"$nextCTIP"$':5015?v=2'

# echo [INFO] Create firewall rules for container "CONTAINERNAME"
echo -e "$info $lng_lxcfw \"$ctName\""

# Creates firewall rules for the container
# Create Firewallgroup - If a port should only be accessible from the local network - IN ACCEPT -source +network -p tcp -dport PORTNUMBER -log nolog
echo -e "[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\nIN ACCEPT -p tcp -dport 5015 -log nolog # Weboberfläche zur Ersteinrichtung\nIN ACCEPT -p tcp -dport 5001 -log nolog # Weboberfläche HTTPs\nIN ACCEPT -p udp -dport 5062 -log nolog # SIP\nIN ACCEPT -p tcp -dport 5062 -log nolog # SIP\nIN ACCEPT -p tcp -dport 5063 -log nolog # secure SIP\nIN ACCEPT -p udp -dport 5090 -log nolog # Tunnel\nIN ACCEPT -p tcp -dport 5090 -log nolog # Tunnel\nIN ACCEPT -p udp -dport 9000:10999 -log nolog # RTP\n\n" >> $clusterfile

# Allow Firewallgroup
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw
