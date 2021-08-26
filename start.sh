#!/bin/bash
#curl -sSL https://raw.githubusercontent.com/shiot/pve_HomeServer/master/start.sh | bash /dev/stdin master

export var_language=$1
export script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/functions.sh"
source "$script_path/language/_languages.sh"
if [ -n ${var_language} ]; then
  source "$script_path/language/$var_language.sh"
  if [[ ${var_language} != "en" ]]; then echo -e "- ${txt_0001} \"${var_language}\""; fi
else
  export var_language=$(whiptail --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --menu "" 20 80 10 "${lng[@]}" 3>&1 1>&2 2>&3)
  source "$script_path/language/$var_language.sh"
  if [[ ${var_language} != "en" ]]; then echo -e "- ${txt_0001} \"${var_language}\""; fi
fi
source "$script_path/helper/variables.sh"
if [ -f "$shiot_configPath/$shiot_configFile" ]; then
  source "$shiot_configPath/$shiot_configFile"
fi

clear
source "$script_path/images/shell_logo.sh"
logo > /tmp/shiot_log.txt
logo

# Checks if Proxmox ist installed
if [ ! -d "/etc/pve/" ]; then
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --textbox "Es wurde keine Proxmox installation gefunden. Dieses Skript kann nur auf Servern mit Proxmox ausgeführt werden!" 10 80
  exit 1
fi

# Checks the PVE MajorRelease
pve_majorversion=$(pveversion | cut -d/ -f2 | cut -d. -f1)
if [ "$pve_majorversion" -lt 6 ]; then
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --textbox "Dieses Skript funktioniert nur auf Servern mit Proxmox Version 6.X oder 7.X" 10 80
  exit 1
fi

function update() {
  function server() {
    {
      echo -e "XXX\n12\nSystem will be updated ...\nXXX"
      apt-get update
      echo -e "XXX\n25\nSystem will be updated ...\nXXX"
      apt-get upgrade -y
      echo -e "XXX\n47\nSystem will be updated ...\nXXX"
      apt-get dist-upgrade -y
      echo -e "XXX\n64\nSystem will be updated ...\nXXX"
      apt-get autoremove -y
      echo -e "XXX\n79\nSystem will be updated ...\nXXX"
      pveam update 2>&1
      echo -e "XXX\n98\nSystem will be updated ...\nXXX"
    } | whiptail --gauge --backtitle "© 2021 - SmartHome-IoT.net" --title "System preparation" "System will be updated, required software will be installed ..." 6 80 0
  }
  if [[ $1 == "server" ]]; then
    server
  elif [[ $1 == "all" ]]; then
    server
    available_lxc=$(pct list | awk '{print $1}' | tail +2 | sed ':M;N;$!bM;s#\n# #g')
    for ctID in $available_lxc; do
      lxc=$(pct list | grep -w ${ctID} | awk '{print $3}')
      if [ -f "$script_path/lxc/${lxc}/update.sh" ]; then
        bash "$script_path/lxc/${lxc}/update.sh"
      fi
    done
  fi
}

function fristRun() {
  # configure Community Repository in Proxmox
  echo -"-- ${txt_0103}"
  echo "#deb https://enterprise.proxmox.com/debian/pve $pve_osname pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list
  echo "deb http://download.proxmox.com/debian/pve $pve_osname pve-no-subscription" > /etc/apt/sources.list.d/pve-community.list

  # Performs a system update and installs software required for this script
  {
    apt-get update 2>&1 >/dev/null
    echo -e "XXX\n29\nInstalliere benötigte Software ...\nXXX"
    apt-get install -y parted smartmontools libsasl2-modules lxc-pve 2>&1 >/dev/null
    echo -e "XXX\n87\nSystemupdate läuft ...\nXXX"
    apt-mark hold keyboard-configuration
    apt-get upgrade -y 2>&1 >/dev/null
    apt-get dist-upgrade -y 2>&1 >/dev/null
    apt-get autoremove -y 2>&1 >/dev/null
    apt-mark unhold keyboard-configuration
    pveam update 2>&1 >/dev/null
    echo -e "XXX\n98\nVorbereitung wird abgeschlossen ...\nXXX"
  } | whiptail --gauge --backtitle "© 2021 - SmartHome-IoT.net" --title "HomeServer vorbereitung" "System wird upgedatet, benötigte Software wird installiert ..." 6 80 0
  echo "- System updated and required software is installed"

  # If no Config Path is found, ask User to recover or to make a new Configuration
  if [ ! -d "$shiot_configPath/" ]; then
    mkdir -p $shiot_configPath
    NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --yesno --yes-button " ${btn_5} " --no-button " ${btn_6} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_1} " "\n${txt_0002}\n\n${txt_0003}\n\n${txt_0004}" 20 80
    yesno=$?
    if [ $yesno -eq 0 ]; then
      cfg_nasIP=
      while ! pingIP $cfg_nasIP; do
        cfg_nasIP=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_2} " "\n${txt_0005}" 6 80 $networkIP. 3>&1 1>&2 2>&3)
      done
      if [ ! -d "/mnt/cfg_temp" ]; then mkdir -p /mnt/cfg_temp; fi
      cfg_dir=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_2} " "\n${txt_0006}" 6 80 Path/to/File 3>&1 1>&2 2>&3)
      cfg_filename=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_2} " "\n${txt_0007}" 6 80 Proxmox_Configuration.txt 3>&1 1>&2 2>&3)
      cfg_mountUser=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_2} " "\n${txt_0008}" 6 80 netrobot 3>&1 1>&2 2>&3)
      cfg_mountPass=$(whiptail --passwordbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_2} " "\n${txt_0009} \"${cfg_mountUser}\"?" 6 80 3>&1 1>&2 2>&3)
      mount -t cifs -o user="$cfg_mountUser",password="$cfg_mountPass",rw,file_mode=0777,dir_mode=0777 //$cfg_nasIP/$cfg_dir /mnt/cfg_temp > /dev/null 2>&1
      cp /mnt/cfg_temp/$cfg_filename "$shiot_configPath/$shiot_configFile" > /dev/null 2>&1
      umount /mnt/cfg_temp > /dev/null 2>&1
      rm -d /mnt/cfg_temp > /dev/null 2>&1
      echo "- ${txt_0010}"
    else
      if bash "$script_path/handler/generate_config.sh" $var_language; then
        echo "- ${txt_0011}"
        # Start and wait for Proxmox Basic configuration if it's not already done
        if bash "$script_path/bin/config_pve.sh"; then
          echo "- ${txt_0013}"
          echo "PVE config OK" >> "$shiot_configPath/helper"
        else
          echo "- ${txt_0014}"
          echo "PVE config not OK" >> "$shiot_configPath/helper"
        fi
      else
        echo "- ${txt_0012}"
        exit
      fi
    fi
  fi
}

function install() {
  if [[ $1 == "LXC" ]]; then
    if bash "$script_path/handler/generate_lxc.sh"; then
      return 0
    else
      return 1
    fi
  elif [[ $1 == "VM" ]]; then
    if bash "$script_path/handler/generate_vm.sh"; then
      return 0
    else
      return 1
    fi
  fi
}

function recover() {
  if [[ $1 == "LXC" ]]; then
    if bash "$script_path/handler/recover_lxc.sh"; then
      return 0
    else
      return 1
    fi
  elif [[ $1 == "VM" ]]; then
    if bash "$script_path/handler/recover_vm.sh"; then
      return 0
    else
      return 1
    fi
  fi
}

function delete() {
  if [[ $1 == "LXC" ]]; then
    if bash "$script_path/handler/delete_lxc.sh"; then
      return 0
    else
      return 1
    fi
  elif [[ $1 == "LXC" ]]; then
    if bash "$script_path/handler/delete_vm.sh"; then
      return 0
    else
      return 1
    fi
  fi
}

function finish() {
  unset script_path
  unset var_language
  if [ -f "/tmp/lxclist.*" ]; then
    rm /tmp/lxclist.*
  fi
  cat /dev/null > ~/.bash_history
  history -c
  history -w
  exit 0
}

function menu() {
  sel=("1" "... meinen Server updaten" \
       "2" "... meinen Server und alle Container aktualisieren" \
       "" "" \
       "3" "... Container installieren und konfigurieren" \
       "4" "... virtuelle Maschinen installieren und Image einbinden" \
       "" "" \
       "5" "... Container aus Backups wiederherstellen" \
       "6" "... virtuelle Maschinen aus Backup wiederherstellen" \
       "" "" \
       "7" "... Container löschen" \
       "8" "... virtuelle Maschine löschen" \
       "" "" \
       "Q" "... beenden und zurück zur Skriptauswahl")
  sel_menu=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " Proxmox HomeServer konfigurieren " "\nWas möchtest Du tun?" 20 80 10 "${sel[@]}" 3>&1 1>&2 2>&3)

  if [[ $sel_menu == "1" ]]; then
    update "server"
    menu
  elif [[ $sel_menu == "2" ]]; then
    update "all"
    menu
  elif [[ $sel_menu == "3" ]]; then
    install "LXC"
    menu
  elif [[ $sel_menu == "4" ]]; then
    install "VM"
    menu
  elif [[ $sel_menu == "5" ]]; then
    recover "LXC"
    menu
  elif [[ $sel_menu == "6" ]]; then
    recover "VM"
    menu
  elif [[ $sel_menu == "7" ]]; then
    delete "LXC"
    menu
  elif [[ $sel_menu == "8" ]]; then
    delete "VM"
    menu
  elif [[ $sel_menu == "Q" ]]; then
    finish
    exit 0
  else
    menu
  fi
}

if [ ! -f "$shiot_configPath/helper" ] || [ $(cat "$shiot_configPath/helper" | grep -cw "PVE config OK") -eq 0 ]; then
  fristRun
  menu
else
  menu
fi

exit
