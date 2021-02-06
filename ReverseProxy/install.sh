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
pct exec $ctID -- bash -ci "dockerd --debug"
pct reboot $ctID --timeout 5
pct exec $ctID -- bash -ci "systemctl start docker && systemctl enable docker > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /root/npm"
pct exec $ctID -- bash -ci "wget -qO /root/npm/config.json $rawGitHubURL/$ctName/config.json"
pct exec $ctID -- bash -ci "wget -qO /root/npm/docker-compose.yml $rawGitHubURL/$ctName/docker-compose.yml"
pct exec $ctID -- bash -ci "sed -i 's+ROOTPASSWORDTOCHANGE+$ctRootpw+g' /root/npm/config.json"
pct exec $ctID -- bash -ci "sed -i 's+ROOTPASSWORDTOCHANGE+$ctRootpw+g' /root/npm/docker-compose.yml"
pct exec $ctID -- bash -ci "cd npm && docker-compose up -d --quiet-pull"

# Container description in the Proxmox web interface
echo "Passwort: $ctRootpw"
pct set $ctID --description $'Shell Login\nBenutzer: root\nPasswort: '"$ctRootpw"$'\n\nWebGUI\nAdresse: http://'"$nextCTIP"$':81\nBenutzer: admin@example.com\nPasswort: changeme'

# Creates firewall rules for the container
echo -e "$info $lxcfw $ctID - $ctName"
echo -e "[group reverseproxy]\n\nIN HTTPS(ACCEPT) -log nolog\nIN HTTP(ACCEPT) -log nolog\nIN ACCEPT -source +network -p tcp -dport 81 -log nolog # Weboberfläche\n\n" >> $clusterfile
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP reverseproxy" > /etc/pve/firewall/$ctID.fw
