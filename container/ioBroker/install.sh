#!/bin/bash

# Container Configuration
# $1=ctTemplate (ubuntu/debian/turnkey-openvpn) - $2=hostname - $3=ContainerRootPasswort - $4=hdd size - $5=cpu cores - $6=RAM Swap/2 - $7=unprivileged 0/1 - $8=features (keyctl=1,nesting=1,mount=cifs)
containerSetup ubuntu $ctName $ctRootpw 8 2 2048 0 "mount=cifs;nfs"

# Comes from Mainscript - start.sh --> Function containerSetup
ctID=$?

# Software that must be installed on the container
# example - containerSoftware="docker.io docker-compose"
containerSoftware=""

# Start Container, because Container stoped aftrer creation
pct start $ctID
sleep 10

# echo [INFO] The container "CONTAINERNAME" is prepared for configuration
echo -e "$info $lng_lxc \"$ctName\" $lng_installlxc1"

# Install the packages specified as containerSoftware
if [[ ! $ontainerSoftware == "" ]]; then
  for package in $containerSoftware; do
    # echo [INFO] "PACKAGENAME" will be installed
    echo -e "$info \"$package\" $lng_installlxc"
    pct exec $nextCTID -- bash -ci "apt-get install -y $package > /dev/null 2>&1"
  done
fi

adapter="parser javascript web vis vis-inventwo vis-icontwo influxdb proxmox"

# Execute commands on containers
pct exec $ctID -- bash -ci "curl -sSL https://deb.nodesource.com/setup_12.x | bash > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y nodejs > /dev/null 2>&1"
pct reboot $ctID --timeout 5
sleep 10
pct exec $ctID -- bash -ci "curl -sLf https://iobroker.net/install.sh | bash > /dev/null 2>&1"
# Install Adapter ioBroker Adapter
for adp in $adapter; do
  # echo [INFO] "PACKAGENAME" will be installed
  echo -e "$info \"$adp\" $lng_installlxc"
  pct exec $ctID -- bash -ci "iobroker add iobroker.$adp --enabled > /dev/null 2>&1"
done

# Execute commands on containers
pct exec $ctID -- bash -ci "iobroker set javascript.0 --enableSetObject true --enableExec true --enableSendToHost true > /dev/null 2>&1"
pct exec $ctID -- bash -ci "iobroker set influxdb.0 --host $(lxc-info $(pct list | grep iDBGrafana | awk '{print $1}') -iH) --user iobroker --password $ctRootpw > /dev/null 2>&1"
pct exec $(pct list | grep iDBGrafana | awk '{print $1}') -- bash -ci 'echo -e "apiVersion: 1\n\ndatasources:\n  - name: ioBroker\n    type: influxdb\n    url: http://localhost:8086\n    access: proxy\n    database: iobroker\n    user: iobroker\n    password: $ctRootpw" > /etc/grafana/provisioning/datasources/iobroker.yaml'
pct exec $ctID -- bash -ci "iobroker set proxmox.0 --ip "$pveIP" --name root --pwd "$varpverootpw" > /dev/null 2>&1"
if [[ $nasexists == "y" ]]; then
  pct exec $ctID -- bash -ci "iobroker add iobroker.backitup --enabled > /dev/null 2>&1 && iobroker set backitup.0 --minimalEnabled true --cifsEnabled true --minimalTime '03:00' --cifsMount $varnasip --cifsUser $varrobotname --cifsPassword $varrobotpw --cifsDir $varnasbackupfolder/ioBroker > /dev/null 2>&1"
  if [[ $varrobotname != "" ]] && [[ $varsynologynas == "y" ]]; then
    pct exec $ctID -- bash -ci "iobroker add iobroker.synology --enabled > /dev/null 2>&1 && iobroker set synology.0 --host $varnasip --login $varrobotname --password $varrobotpw > /dev/null 2>&1"
  fi
fi
if [[ $vargwmanufacturer == "unifi" ]]; then
  pct exec $ctID -- bash -ci "iobroker add iobroker.unifi --enabled > /dev/null 2>&1"
  whiptail --yesno --backtitle "SmartHome-IoT.net - $ctName" --title "Ubiqiti / Unifi" "Hat dein Netzwerkroboter \"$varrobotname\" Superadminrechte auf deinem Unifi Controller?" ${r} ${c}
    yesno=$?
    if [[ $yesno == 0 ]]; then
      pct exec $ctID -- bash -ci "iobroker set unifi.0 --controllerIp $gatewayIP --controllerUsername $varrobotname --controllerPassword $varrobotpw > /dev/null 2>&1"
    else
      vargwadmin=$(whiptail --inputbox --nocancel --backtitle "SmartHome-IoT.net - $ctName" --title "Ubiqiti / Unifi" "Wie lautet der Benutzername eines Benutzers mit Administratorrechten?" ${r} ${c} 3>&1 1>&2 2>&3)
      vargwadminpw=$(whiptail --inputbox --nocancel --backtitle "SmartHome-IoT.net - $ctName" --title "Ubiqiti / Unifi" "Wie lautet das Passwort zu diesem Benutzer?" ${r} ${c} 3>&1 1>&2 2>&3)
      pct exec $ctID -- bash -ci "iobroker set unifi.0 --controllerIp $gatewayIP --controllerUsername $vargwadmin --controllerPassword $vargwadminpw > /dev/null 2>&1"
    fi
elif [[ $vargwmanufacturer == "avm" ]]; then
  pct exec $ctID -- bash -ci "iobroker add iobroker.tr-064 --enabled > /dev/null 2>&1"
  whiptail --yesno --backtitle "SmartHome-IoT.net - $ctName" --title "AVM" "Hat dein Netzwerkroboter \"$varrobotname\" Adminrechte auf deiner FRITZ!Box?" ${r} ${c}
    yesno=$?
    if [[ $yesno == 0 ]]; then
      pct exec $ctID -- bash -ci "iobroker set tr-064.0 --iporhost $gatewayIP --user $varrobotname --password $varrobotpw > /dev/null 2>&1"
    else
      vargwadmin=$(whiptail --inputbox --nocancel --backtitle "SmartHome-IoT.net - $ctName" --title "AVM" "Wie lautet der Benutzername eines Benutzers mit Administratorrechten?" ${r} ${c} 3>&1 1>&2 2>&3)
      vargwadminpw=$(whiptail --inputbox --nocancel --backtitle "SmartHome-IoT.net - $ctName" --title "AVMi" "Wie lautet das Passwort zu diesem Benutzer?" ${r} ${c} 3>&1 1>&2 2>&3)
      pct exec $ctID -- bash -ci "iobroker set tr-064.0 --iporhost $gatewayIP --user $vargwadmin --password $vargwadminpw > /dev/null 2>&1"
    fi      
fi
pct exec $ctID -- bash -ci "iobroker passwd admin --password changeme > /dev/null 2>&1"
pct exec $ctID -- bash -ci "iobroker set admin.0 --auth true > /dev/null 2>&1"

# Container description in the Proxmox web interface
pct set $ctID --description $'Shell Login\nBenutzer: root\nPasswort: '"$ctRootpw"$'\n\nWebGUI\nAdresse: http://'"$nextCTIP"$':8081\nBenutzer: adminm\nPasswort: changeme'

# echo [INFO] Create firewall rules for container "CONTAINERNAME"
echo -e "$info $lng_lxcfw \"$ctName\""

# Creates firewall rules for the container
# Create Firewallgroup - If a port should only be accessible from the local network - IN ACCEPT -source +network -p tcp -dport PORTNUMBER -log nolog
echo -e "[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\nIN HTTPS(ACCEPT) -log nolog\nIN HTTP(ACCEPT) -log nolog\nIN ACCEPT -source +network -p tcp -dport 1880 -log nolog #node-red\nIN ACCEPT -source +network -p tcp -dport 1883 -log nolog #mqtt\nIN ACCEPT -source +network -p tcp -dport 2001 -log nolog #homematic\nIN ACCEPT -source +network -p tcp -dport 8081 -log nolog #iobroker admin\nIN ACCEPT -source +network -p tcp -dport 8082 -log nolog #iobroker vis\nIN ACCEPT -source +network -p tcp -dport 8282 -log nolog #flot\n\n" >> $clusterfileFW

# Allow Firewallgroup
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw
