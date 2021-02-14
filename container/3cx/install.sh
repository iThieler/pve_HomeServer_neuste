#!/bin/bash
{

  # Container Configuration
  # $1=ctTemplate (ubuntu/debian/turnkey-openvpn) - $2=hostname - $3=ContainerRootPasswort - $4=hdd size - $5=cpu cores - $6=RAM Swap/2 - $7=unprivileged 0/1 - $8=features (keyctl=1,nesting=1,mount=cifs)
  lxcSetup debian9 $ctName $ctRootpw 8 1 1024 0 "mount=cifs;nfs"

  # Comes from Mainscript - start.sh --> Function lxcSetup
  ctID=$(pct list | grep ${ctName} | awk $'{print $1}')

  # Software that must be installed on the container
  # example - containerSoftware="docker.io docker-compose"
  containerSoftware="apt-transport-https iperf libicu57 dphys-swapfile"

  # Start Container, because Container stoped aftrer creation
  pct start $ctID
  sleep 10

  # echo [INFO] The container "CONTAINERNAME" is prepared for configuration
  echo -e "XXX\n55\n$lng_lxc_create_text_software_install\nXXX"

  # Install the packages specified as containerSoftware
  for package in $containerSoftware; do
    pct exec $nextCTID -- bash -c "apt-get install -y $package > /dev/null 2>&1"
  done

  # Execute commands on containers
  echo -e "XXX\n59\n$lng_lxc_create_text_package_install - \"3cx\"\nXXX"
  pct exec $ctID -- bash -ci "wget -qO - http://downloads-global.3cx.com/downloads/3cxpbx/public.key | apt-key add - > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "echo ""deb http://downloads-global.3cx.com/downloads/debian stretch main"" | tee /etc/apt/sources.list.d/3cxpbx.list > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
  whiptail --msgbox --backtitle "SmartHome-IoT.net - 3cx" --title "!!! HINWEIS !!!" "Im folgenden Dialog musst du die Lizenzbedingeungen von 3cx akzeptieren. Auf OK gelangst du mit der Tabulator-Taste und bestätigen tust du mit der Enter-Taste. Anschlißend wählst du Option 1 um 3cx über die Weboberfläsche zu Installieren/Konfigurieren. Die Web-Adresse findest Du nach der Installation in der Containerbeschreibung in Proxmox." 20 70
  pct exec $ctID -- bash -ci "apt-get -y install 3cxpbx"

  # Container description in the Proxmox web interface
  echo -e "XXX\n99\n$lng_lxc_create_text_firewall\nXXX"
  pct set $ctID --description $'Shell Login\nBenutzer: root\nPasswort: '"$ctRootpw"$'\n\nAdministrations WebGUI\nAdresse: https://'"$nextCTIP"$':5001\nBenutzer: \nPasswort: \n\nBenutzer WebGUI\nAdresse: https://'"$nextCTIP"$':5001/webclient\nBenutzer: Nebenstellennummer \nPasswort: per E-Mail erhalten\n\nWebGUI Ersteinrichtung\nAdresse: http://'"$nextCTIP"$':5015?v=2'

  # Creates firewall rules for the container
  # Create Firewallgroup - If a port should only be accessible from the local network - IN ACCEPT -source +network -p tcp -dport PORTNUMBER -log nolog
  echo -e "[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\nIN ACCEPT -p tcp -dport 5015 -log nolog # Weboberfläche zur Ersteinrichtung\nIN ACCEPT -p tcp -dport 5001 -log nolog # Weboberfläche HTTPs\nIN ACCEPT -p udp -dport 5062 -log nolog # SIP\nIN ACCEPT -p tcp -dport 5062 -log nolog # SIP\nIN ACCEPT -p tcp -dport 5063 -log nolog # secure SIP\nIN ACCEPT -p udp -dport 5090 -log nolog # Tunnel\nIN ACCEPT -p tcp -dport 5090 -log nolog # Tunnel\nIN ACCEPT -p udp -dport 9000:10999 -log nolog # RTP\n\n" >> $clusterfileFW

  # Allow Firewallgroup
  echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw

  # Graphical installation progress display
} | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_lxc_setup" --title "$lng_lxc_create_title - $ctName" --gauge "$lng_lxc_setup_text" 6 60 0
