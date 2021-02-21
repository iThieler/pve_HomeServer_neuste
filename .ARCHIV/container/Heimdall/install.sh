#!/bin/bash
{

  # Container Configuration
  # $1=ctTemplate (ubuntu/debian/turnkey-openvpn) - $2=hostname - $3=hdd size - $4=cpu cores - $5=RAM Swap/2 - $6=unprivileged 0/1 - $7=features (keyctl=1,nesting=1,mount=cifs)
  lxcSetup ubuntu ${ctName} 4 1 256 1 "keyctl=1,nesting=1"

  # Comes from Mainscript - start.sh --> Function lxcSetup
  ctID=$(pct list | grep ${ctName} | awk $'{print $1}')

  # Software that must be installed on the container
  # example - containerSoftware="docker.io docker-compose"
  containerSoftware="docker.io docker-compose"

  # Start Container, because Container stoped aftrer creation
  pct start $ctID
  sleep 10

  # echo [INFO] The container "CONTAINERNAME" is prepared for configuration
  echo -e "XXX\n55\n${lng_lxc_create_text_software_install}\nXXX"

  # Install the packages specified as containerSoftware
  for package in $containerSoftware; do
    pct exec ${nextCTID} -- bash -c "apt-get install -y $package > /dev/null 2>&1"
  done

  # Execute commands on containers
  echo -e "XXX\n59\n${lng_lxc_create_text_package_install}\nXXX"
  pct exec ${ctID} -- bash -ci "systemctl start docker && systemctl enable docker > /dev/null 2>&1"
  pct exec ${ctID} -- bash -ci "mkdir -p /root/heimdall"
  pct exec ${ctID} -- bash -ci "wget -qO /root/heimdall/docker-compose.yml ${rawGitHubURL}/container/${ctName}/docker-compose.yml"
  pct exec ${ctID} -- bash -ci "cd heimdall && docker-compose up -d --quiet-pull > /dev/null 2>&1"

  # Container description in the Proxmox web interface
  pct set ${ctID} --description $'Shell Login\nBenutzer: root\nPasswort: '"${ctRootpw}"$'\n\nWebGUI\nAdresse: http://'"${nextCTIP}"$'\nAdresse: https://'"${nextCTIP}"$'\n'

  # echo [INFO] Create firewall rules for container "CONTAINERNAME"
  echo -e "XXX\n99\n${lng_lxc_create_text_firewall}\nXXX"

  # Create Firewallgroup - If a port should only be accessible from the local network - IN ACCEPT -source +network -p tcp -dport PORTNUMBER -log nolog
  echo -e "[group $(echo ${ctName}|tr "[:upper:]" "[:lower:]")]\n\nIN HTTPS(ACCEPT) -source +network -log nolog\nIN HTTP(ACCEPT) -source +network -log nolog" >> ${clusterfileFW}

  # Allow Firewallgroup
  echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo ${ctName}|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/${ctID}.fw

# Graphical Feedback of Installation with gauge
} | whiptail --backtitle "© 2021 - SmartHome-IoT.net - ${lng_lxc_setup}" --title "${lng_lxc_setup_title} - $ctName" --gauge "${lng_lxc_setup_text}" 6 70 0
