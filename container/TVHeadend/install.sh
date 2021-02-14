#!/bin/bash
{

  # Container Configuration
  # $1=ctTemplate (ubuntu/debian/turnkey-openvpn) - $2=hostname - $3=ContainerRootPasswort - $4=hdd size - $5=cpu cores - $6=RAM Swap/2 - $7=unprivileged 0/1 - $8=features (keyctl=1,nesting=1,mount=cifs)
  lxcSetup ubuntu $ctName 4 1 1024 0 "nesting=1,mount=cifs;nfs"

  # Comes from Mainscript - start.sh --> Function lxcSetup
  ctID=$(pct list | grep ${ctName} | awk $'{print $1}')

  # Software that must be installed on the container
  # example - containerSoftware="docker.io docker-compose"
  containerSoftware="cifs-utils apt-transport-https coreutils lsb-release ca-certificates"

  # Start Container, because Container stoped aftrer creation
  pct start $ctID
  sleep 10

  # echo [INFO] The container "CONTAINERNAME" is prepared for configuration
  echo -e "XXX\n55\n${lng_lxc_create_text_software_install}\nXXX"

  # Install the packages specified as containerSoftware
  for package in $containerSoftware; do
    # echo [INFO] "PACKAGENAME" will be installed
    pct exec $nextCTID -- bash -c "apt-get install -y $package > /dev/null 2>&1"
  done

  # Execute commands on containers
  echo -e "XXX\n59\n${lng_lxc_create_text_package_install} - \"TVHeadend\"\nXXX"
  pct exec $ctID -- bash -ci "apt-add-repository -y ppa:mamarley/tvheadend-git-stable > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
  if [ $(ls -la /dev/dvb/ | grep -c adapter0) -eq 1 ]; then
    pct shutdown $ctID --timeout 0
    sleep 10
    echo -e "XXX\n68\n${lng_lxc_create_text_dvb}\nXXX"
    dvbid=$(ls -la /dev/dvb/adapter0 | grep video | head -n1 | awk '{print $5}' | cut -d, -f1)
    echo "lxc.cgroup.devices.allow: c $dvbid:* rwm" >> /etc/pve/lxc/$ctID.conf
    echo "lxc.mount.entry: /dev/dvb dev/dvb none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
    pct start $ctID
    sleep 10
  fi
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
    echo -e "XXX\n97\n${lng_lxc_create_text_nas}\nXXX"
    lxcMountNAS $ctID
    pct exec $ctID -- bash -ci "if [ ! -d \"/media/Records\" ]; then mkdir -p \"/media/Records\"; fi"
  fi
  pct exec $ctID -- bash -ci "apt-get install -y tvheadend > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "systemctl start tvheadend && systemctl enable tvheadend > /dev/null 2>&1"

  # Container description in the Proxmox web interface
  pct set $ctID --description $'Shell Login\nBenutzer: root\nPasswort: '"$ctRootpw"$'\n\nWebGUI\nAdresse: http://'"$nextCTIP"$':9981'"$nasFolder"$'\n\nPicons/Kanalsymbole\nAdresse: https://marhycz.github.io/picons/1024/%C.png'

  # echo [INFO] Create firewall rules for container "CONTAINERNAME"
  echo -e "XXX\n99\n${lng_lxc_create_text_firewall}\nXXX"

  # Creates firewall rules for the container
  # Create Firewallgroup - If a port should only be accessible from the local network - IN ACCEPT -source +network -p tcp -dport PORTNUMBER -log nolog
  echo -e "[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\nIN ACCEPT -p tcp -dport 9982 -log nolog # HTSP (Streaming protocol)\nIN ACCEPT -source +network -p tcp -dport 9981 -log nolog # Weboberfläche\n\n" >> $clusterfileFW

  # Allow Firewallgroup
  echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw

  # Graphical installation progress display
} | whiptail --backtitle "© 2021 - SmartHome-IoT.net - ${lng_lxc_setup}" --title "${lng_lxc_create_title} - $ctName" --gauge "${lng_lxc_setup_text}" 6 60 0
