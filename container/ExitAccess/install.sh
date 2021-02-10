#!/bin/bash

# Container Configuration
# $1=ctTemplate (ubuntu/debian/turnkey-openvpn) - $2=hostname - $3=ContainerRootPasswort - $4=hdd size - $5=cpu cores - $6=RAM Swap/2 - $7=unprivileged 0/1 - $8=features (keyctl=1,nesting=1,mount=cifs)
containerSetup ubuntu $ctName $ctRootpw 4 1 512 1 ""

# Comes from Mainscript - start.sh --> Function containerSetup
ctID=$?

# Software that must be installed on the container
# example - containerSoftware="docker.io docker-compose"
containerSoftware="samba samba-common-bin"

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

function addVPNUser() {
  pw=$(createPassword 12)
  vpnuser=$(whiptail --inputbox --nocancel --backtitle "SmartHome-IoT.net - piVPN" --title "Benutzer" "Um Verbindungsprobleme zu vermeiden, sollte pro Endgerät das sich\nverbindet ein eigener Benutzer erstellt werden.\n\nWelchen Namen soll der VPN-Benutzer erhalten?" 20 70 MaxHandy 3>&1 1>&2 2>&3)
  whiptail --msgbox --backtitle "SmartHome-IoT.net - piVPN" --title "Benutzer" "Es wird ein Benutzer mit folgenden Daten erstellt:\nBenutzer  $vpnuser\nPasswort  $pw\n\nDas Konto ist 1800 Tage gültig" 20 70
  pct exec $ctID -- bash -ci "pivpn add -n $vpnuser -p $pw -d 1800"
  pct exec $ctID -- bash -ci "chmod -R 775 /home/pivpn/ovpns"
  whiptail --yesno --backtitle "SmartHome-IoT.net - piVPN" --title "Benutzer" "Möchtest du einen weiteren VPN Benutzer anlegen?" 20 70
  yesno=$?
  if [[ $yesno == 0 ]]; then
    addVPNUser
  else
    return 0
  fi
}

# Execute commands on containers
# Install and configure piHole
pct exec $ctID -- bash -ci "mkdir -p /etc/pihole/"
pct exec $ctID -- bash -ci "wget -qO /etc/pihole/setupVars.conf $rawGitHubURL/container/$ctName/piHole_setupVars.conf"
pct exec $ctID -- bash -ci "sed -i 's#IPADRESSTOCHANGE#$nextCTIP#g' /etc/pihole/setupVars.conf"
pct exec $ctID -- bash -ci "sed -i 's#CIDRTOCHANGE#$cidr#g' /etc/pihole/setupVars.conf"
pct exec $ctID -- bash -ci "curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended > /dev/null 2>&1"
pct exec $ctID -- bash -ci "/usr/local/bin/pihole -a -p changeme > /dev/null 2>&1"       # Change the piHole Webinterface Password to changeme
pct exec $ctID -- bash -ci "systemctl stop lighttpd && systemctl disable lighttpd > /dev/null 2>&1"
pct exec $ctID -- bash -ci "curl -sSL $rawGitHubURL/container/$ctName/updateAdlistPihole.sh | bash"
# Install and configure piVPN
pct exec $ctID -- bash -ci "useradd -m -p $ctRootpw pivpn"
pct exec $ctID -- bash -ci "mkdir -p /etc/pivpn/openvpn/"
pct exec $ctID -- bash -ci "wget -qO /etc/pivpn/openvpn/setupVars.conf $rawGitHubURL/container/$ctName/piVPN_setupVars.conf"
publicIP=$(dig @resolver4.opendns.com myip.opendns.com +short)
hostname=$(whiptail --inputbox --nocancel --backtitle "SmartHome-IoT.net - piVPN" --title "Hostname - öffentliche IP" "Wie lautet der Hostname (FQDN) oder die öffentliche IP zu diesem Container?" ${r} ${c} $publicIP 3>&1 1>&2 2>&3)
pct exec $ctID -- bash -ci "sed -i 's#HOSTTOCHANGE#$hostname#g' /etc/pihole/setupVars.conf" #vpn.thielshome.de
pct exec $ctID -- bash -ci "curl -sSL https://install.pivpn.io | bash /dev/stdin --unattended /etc/pivpn/openvpn/setupVars.conf > /dev/null 2>&1"
# Configure Samba
pct exec $ctID -- bash -ci "rm /etc/samba/smb.conf"
pct exec $ctID -- bash -ci "wget -qO /etc/samba/smb.conf $rawGitHubURL/container/$ctName/samba.conf"
pct exec $ctID -- bash -ci "chmod -R 775 /home/pivpn/ovpns"
pct exec $ctID -- bash -ci "systemctl restart smbd"
addVPNUser

# Container description in the Proxmox web interface
pct set $ctID --description $'Shell Login\nBenutzer: root\nPasswort: '"$ctRootpw"$'\n\nWebGUI\nAdresse: http://'"$nextCTIP"$'/admin\nPasswort: changeme'

# echo [INFO] Create firewall rules for container "CONTAINERNAME"
echo -e "$info $lng_lxcfw \"$ctName\""

# Creates firewall rules for the container
# Create Firewallgroup - If a port should only be accessible from the local network - IN ACCEPT -source +network -p tcp -dport PORTNUMBER -log nolog
echo -e "[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\nIN HTTPS(ACCEPT) -log nolog\nIN HTTP(ACCEPT) -log nolog\nIN ACCEPT -source +pnetwork -p tcp -dport 53 -log nolog\nIN ACCEPT -source +pnetwork -p udp -dport 53 -log nolog\nIN ACCEPT -source +network -p udp -dport 67 -log nolog\nIN ACCEPT -source +network -p tcp -dport 4711 -log nolog\n\n" >> $clusterfileFW

# Allow Firewallgroup
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw
