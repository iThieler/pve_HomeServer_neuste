#!/bin/bash

export var_language=$1
export script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/functions.sh"
source "$script_path/language/_languages.sh"
if [ -n ${var_language} ]; then
  source "$script_path/language/$var_language.sh"
  if [[ ${var_language} != "en" ]]; then echoLOG b "${txt_0001} \"${var_language}\""; fi
else
  export var_language=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" "\nSelect your Language" 20 80 10 "${lng[@]}" 3>&1 1>&2 2>&3)
  source "$script_path/language/$var_language.sh"
  if [[ ${var_language} != "en" ]]; then echoLOG b "${txt_0001} \"${var_language}\""; fi
fi
source "$script_path/helper/variables.sh"
if [ -f "$shiot_configPath/$shiot_configFile" ]; then
  source "$shiot_configPath/$shiot_configFile"
fi

clear
if [ ! -d "$shiot_configPath/" ]; then mkdir -p $shiot_configPath; fi
source "$script_path/images/shell_logo.sh"
logo > "$shiot_configPath/$shiot_logfile"
logo

# Checks if Proxmox ist installed
if [ ! -d "/etc/pve/" ]; then
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --textbox --backtitle "© 2021 - SmartHome-IoT.net" --title "${tit_0001}" "\n${txt_0002}" 10 80
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
    whiptail --textbox --backtitle "© 2021 - SmartHome-IoT.net" --title "${tit_0001}" "\n${txt_0003}" 10 80
  exit 1
fi

function update() {
  function server() {
    {
      echo -e "XXX\n12\n${txt_0005} ...\nXXX"
      apt-get update
      echo -e "XXX\n25\n${txt_0005} ...\nXXX"
      apt-get upgrade -y
      echo -e "XXX\n47\n${txt_0005} ...\nXXX"
      apt-get dist-upgrade -y
      echo -e "XXX\n64\n${txt_0005} ...\nXXX"
      apt-get autoremove -y
      echo -e "XXX\n79\n${txt_0005} ...\nXXX"
      pveam update 2>&1
      echo -e "XXX\n98\n${txt_0005} ...\nXXX"
    } | whiptail --gauge --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0002} " "\n${txt_0004} ..." 10 80 0
  }
  if [[ $1 == "server" ]]; then
    server
  elif [[ $1 == "all" ]]; then
    server
    available_lxc=$(pct list | awk '{print $1}' | tail +2 | sed ':M;N;$!bM;s#\n# #g')
    for ctID in $available_lxc; do
      lxc=$(pct list | grep -w ${ctID} | awk '{print $3}')
      if [ -f "$script_path/lxc/${lxc}/update.sh" ]; then
        bash "$script_path/lxc/${lxc}/update.sh" $var_language
      fi
    done
  fi
}

function fristRun() {
  # configure Community Repository in Proxmox
  echoLOG b "${txt_0006}"
  echo "#deb https://enterprise.proxmox.com/debian/pve $pve_osname pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list
  echo "deb http://download.proxmox.com/debian/pve $pve_osname pve-no-subscription" > /etc/apt/sources.list.d/pve-community.list

  {
  # Performs a system update and installs software required for this script
    apt-get update 2>&1 >/dev/null
    echo -e "XXX\n29\n${txt_0008} ...\nXXX"
    apt-get install -y parted smartmontools libsasl2-modules mailutils lxc-pve 2>&1 >/dev/null
    echo -e "XXX\n87\n${txt_0005} ...\nXXX"
    apt-mark hold keyboard-configuration
    apt-get upgrade -y 2>&1 >/dev/null
    apt-get dist-upgrade -y 2>&1 >/dev/null
    apt-get autoremove -y 2>&1 >/dev/null
    apt-mark unhold keyboard-configuration
    pveam update 2>&1 >/dev/null
    echo -e "XXX\n98\n${txt_0009} ...\nXXX"
  } | whiptail --gauge --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0002} " "\n${txt_0007} ..." 10 80 0
  echoLOG g "${txt_0010}"

  # If no Config File is found, ask User to recover or to make a new Configuration
  if [ ! -f "$shiot_configPath/$shiot_configFile" ]; then
    NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --yesno --yes-button " ${btn_5} " --no-button " ${btn_6} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0001} " "\n${txt_0011}\n\n${txt_0012}" 20 80
    yesno=$?
    if [ $yesno -eq 0 ]; then # Recovery
      if [ ! -d "/mnt/cfg_temp" ]; then mkdir -p /mnt/cfg_temp; fi
      whiptail --yesno --yes-button " ${btn_7} " --no-button " ${btn_8} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0013}" 10 80
      yesno=$?
      if [ $yesno -eq 0 ]; then # Mount Network Share and copy File
        cfg_IP=
        while ! pingIP $cfg_IP; do
          cfg_IP=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0014}" 10 80 $networkIP. 3>&1 1>&2 2>&3)
        done
        cfg_dir=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0015}" 10 80 Path/to/File 3>&1 1>&2 2>&3)
        cfg_filename=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0016}" 10 80 SHIoT_configuration.txt 3>&1 1>&2 2>&3)
        cfg_mountUser=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0017}" 10 80 netrobot 3>&1 1>&2 2>&3)
        cfg_mountPass=$(whiptail --passwordbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0018} \"${cfg_mountUser}\"?" 10 80 3>&1 1>&2 2>&3)
        mount -t cifs -o user="$cfg_mountUser",password="$cfg_mountPass",rw,file_mode=0777,dir_mode=0777 //$cfg_IP/$cfg_dir /mnt/cfg_temp > /dev/null 2>&1
        cp "/mnt/cfg_temp/$cfg_filename" "$shiot_configPath/$shiot_configFile" > /dev/null 2>&1
        umount /mnt/cfg_temp > /dev/null 2>&1
        echoLOG g "${txt_0019}: //$cfg_IP/$cfg_dir"
      elif [ $yesno -eq 1 ]; then # ask for local or external file
        whiptail --yesno --yes-button " ${btn_9} " --no-button " ${btn_10} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0020}" 10 80
        yesno=$?
        if [ $yesno -eq 0 ]; then # Mount USB Media and copy File
          cfg_disk=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0021}" 10 80 /dev/ 3>&1 1>&2 2>&3)
          cfg_dir=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0015}" 10 80 Path/to/File 3>&1 1>&2 2>&3)
          cfg_filename=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0016}" 10 80 SHIoT_configuration.txt 3>&1 1>&2 2>&3)
          mount $cfg_disk /mnt/cfg_temp
          cp "/mnt/cfg_temp/$cfg_dir/$cfg_filename" "$shiot_configPath/$shiot_configFile" > /dev/null 2>&1
          umount $cfg_disk
          echoLOG g "${txt_0019}: $cfg_disk/$cfg_dir"
        elif [ $yesno -eq 1 ]; then # copy File
          cfg_path=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0022}" 10 80 /dev/ 3>&1 1>&2 2>&3)
          cfg_filename=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0003} " "\n${txt_0016}" 10 80 SHIoT_configuration.txt 3>&1 1>&2 2>&3)
          cp "/$cfg_path/$cfg_filename" "$shiot_configPath/$shiot_configFile" > /dev/null 2>&1
          echoLOG g "${txt_0019}: $cfg_path"
        fi
      fi
      rm "/mnt/cfg_temp/" > /dev/null 2>&1

    else
      if bash "$script_path/handler/generate_config.sh" $var_language; then
        echoLOG g "${txt_0023}"
      else
        echoLOG r "${txt_0026}"
        exit 1
      fi
    fi

    # Start and wait for Proxmox Basic configuration if it's not already done
    if bash "$script_path/bin/config_pve.sh" $var_language; then
      echoLOG g "${txt_0024}"
      echo "PVE config OK" >> "$shiot_configPath/helper"
      source "$shiot_configPath/$shiot_configFile"
      menu
    else
      echoLOG r "${txt_0025}"
      echo "PVE config not OK" >> "$shiot_configPath/helper"
      exit 1
    fi
  fi
}

function install() {
  if [[ $1 == "LXC" ]]; then
    if bash "$script_path/handler/generate_lxc.sh" $var_language; then
      return 0
    else
      return 1
    fi
  elif [[ $1 == "VM" ]]; then
    if bash "$script_path/handler/generate_vm.sh" $var_language; then
      return 0
    else
      return 1
    fi
  fi
}

function recover() {
  if [[ $1 == "LXC" ]]; then
    if bash "$script_path/handler/recover_lxc.sh" $var_language; then
      return 0
    else
      return 1
    fi
  elif [[ $1 == "VM" ]]; then
    if bash "$script_path/handler/recover_vm.sh" $var_language; then
      return 0
    else
      return 1
    fi
  fi
}

function delete() {
  if [[ $1 == "LXC" ]]; then
    if bash "$script_path/handler/delete_lxc.sh" $var_language; then
      return 0
    else
      return 1
    fi
  elif [[ $1 == "LXC" ]]; then
    if bash "$script_path/handler/delete_vm.sh" $var_language; then
      return 0
    else
      return 1
    fi
  fi
}

function finish() {
  echo -e "${txt_0037}" | mail.mailutils -a "From: \"${wrd_0006}\" <${var_senderaddress}>" -s "[SHIoT] ${wrd_0020}" "${var_rootmail}" -A "$shiot_configPath/$shiot_logfile"
  unset script_path
  unset var_language
  if [ -f "/tmp/lxclist.*" ]; then rm /tmp/lxclist.*; fi
  cat /dev/null > ~/.bash_history
  history -c
  history -w
  exit 0
}

function menu() {
  sel=("1" "... ${txt_0027}" \
       "2" "... ${txt_0028}" \
       "" "" \
       "3" "... ${txt_0029}" \
       "4" "... ${txt_0030}" \
       "" "" \
       "5" "... ${txt_0031}" \
       "6" "... ${txt_0032}" \
       "" "" \
       "7" "... ${txt_0033}" \
       "8" "... ${txt_0034}" \
       "" "" \
       "Q" "... ${txt_0035}")
  sel_menu=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0004} " "\n${txt_0036}" 20 80 10 "${sel[@]}" 3>&1 1>&2 2>&3)

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

if [ ! -f "$shiot_configPath/helper" ] || [ $(cat "$shiot_configPath/helper" | grep -cw "PVE config OK") -eq 0 ]; then fristRun; fi

menu
