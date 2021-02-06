#!/bin/bash

# Container Configuration
containerSetup ubuntu $ctName $ctRootpw 8 1 512 "keyctl=1,nesting=1"

# Comes from Mainscript - start.sh --> Function containerSetup
ctID=$?

# Software that must be installed on the container
containerSoftware="docker.io docker-compose"

# Start Container
pct start $ctID
sleep 10

echo -e "$info $lxc $ctID - $ctName $installlxc1"

for package in $containerSoftware; do
  echo -e "$info $package $installlxc"
  pct exec $nextCTID -- bash -c "apt-get install -y $package > /dev/null 2>&1"
done
pct exec $ctID -- bash -ci ""

# Container description in the Proxmox web interface
pct set $ctID --description $'Shell Login\nBenutzer: root\nPasswort: '"$ctRootpw"$'\n\nWebGUI\nAdresse: http://'"$nextCTIP"$':81\nBenutzer: admin@example.com\nPasswort: changeme'

# Creates firewall rules for the container
echo -e "$info $lxcfw $ctID - $ctName"
echo -e "[group idbgrafana]\n\nIN ACCEPT -source +network -p tcp -dport 3000 -log nolog # Grafana Weboberfläche\nIN ACCEPT -source +network -p tcp -dport 8091 -log nolog # Meta nodes\nIN ACCEPT -source +network -p udp -dport 8089 -log nolog # Proxmox Verbindung\nIN ACCEPT -source +network -p tcp -dport 8089 -log nolog # Meta nodes\nIN ACCEPT -source +network -p tcp -dport 8088 -log nolog # other data nodes\nIN ACCEPT -source +network -p tcp -dport 8086 -log nolog # InfluxDB HTTP service\n\n" >> $fwcluster
