#!/bin/bash

function githubLatest() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# check its master curl -sSL https://raw.githubusercontent.com/shiot/pve_HomeServer/master/start.sh | bash /dev/stdin master
if [[ $1 == "master" ]]; then
  gh_tag="master"
  gh_download="https://github.com/shiot/pve_HomeServer/archive/refs/heads/master.tar.gz"
else
  gh_tag=$(githubLatest "shiot/pve_HomeServer")
  gh_download="https://github.com/shiot/pve_HomeServer/archive/refs/tags/${gh_tag}.tar.gz"
fi

clear
source <(curl -sSL https://raw.githubusercontent.com/shiot/pve_HomeServer/${gh_tag}/logo.sh)
logo

# Checks if Proxmox ist installed
if [ ! -d "/etc/pve/"]
  echo "No Proxmox installation was found. This script can be executed only on Proxmox servers!"
  exit 1
fi

# Checks the PVE MajorRelease
pve_majorversion=$(pveversion | cut -d/ -f2 | cut -d. -f1)
if [ ${pve_majorversion} -ne 6 ]; then
  echo "- This script currently works only for Proxmox version 6.X"
  exit 1
fi

# Performs a system update and installs software required for this script
{
  apt-get update 2>&1 >/dev/null
  percent=29
  echo -e "XXX\n$percent\nInstall required software ...\nXXX"
  for package in "parted smartmontools libsasl2-modules lxc-pve"; do
    percent=$(( $percent + 11 ))
    if [ $(dpkg-query -W -f='${Status}' "$package" | grep -c "ok installed") -eq 0 ]; then
      echo -e "XXX\n$percent\nInstall required software - $package ...\nXXX"
      apt-get install -y "$package" 2>&1 >/dev/null
    fi
  done
  echo -e "XXX\n87\nSystem will be updated ...\nXXX"
  apt-get dist-upgrade -y 2>&1 >/dev/null && apt-get autoremove -y 2>&1 >/dev/null && pveam update 2>&1 >/dev/null
  echo -e "XXX\n98\nCopy gitHub repository ...\nXXX"
  wget -c $gh_download -O - | tar -xz
  mv pve_HomeServer-${gh_tag}/ pve_HomeServer/
} | whiptail --backtitle "© 2021 - SmartHome-IoT.net" --title "System preparation" --gauge "System will be updated, required software will be installed ..." 10 80 0
echo "- System updated and required software installed"

# Enter script Dir and load required files
cd pve_HomeServer/
source handler/global_functions.sh
source bin/variables.sh
source language/_languages.sh

# Choose Script Language
var_language=$(whiptail --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --menu "" 20 80 10 "${lng[@]}" 3>&1 1>&2 2>&3)
source language/$var_language.sh

# If no Config Path is found, ask User to recover or to make a new Configuration
if [ ! -d "$shiot_configPath" ]; then
  mkdir -p $shiot_configPath
  NEWT_COLORS='
    window=black,red
    border=white,red
    textbox=white,red
    button=black,yellow
  ' \
  whiptail --yesno --yes-button " ${btn_5} " --no-button " ${btn_6} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_1} " "\n${txt_0001}\n\n${txt_0002}\n\n${txt_0003}" 20 80
  yesno=$?
  if [ $yesno -eq 0 ]; then
    cfg_nasIP=
    while ! pingIP $cfg_nasIP; do
      cfg_nasIP=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_2} " "\n${txt_0004}" 10 80 $networkIP. 3>&1 1>&2 2>&3)
    done
    if [ ! -d "/mnt/cfg_temp" ]; then mkdir -p /mnt/cfg_temp; fi
    cfg_dir=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_2} " "\n${txt_0005}" 10 80 Path/to/File 3>&1 1>&2 2>&3)
    cfg_filename=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_2} " "\n${txt_0006}" 10 80 Proxmox_Configuration.txt 3>&1 1>&2 2>&3)
    cfg_mountUser=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_2} " "\n${txt_0007}" 10 80 netrobot 3>&1 1>&2 2>&3)
    cfg_mountPass=$(whiptail --passwordbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_2} " "\n${txt_0008} \"${cfg_mountUser}\"?" 10 80 3>&1 1>&2 2>&3)
    mount -t cifs -o user="$cfg_mountUser",password="$cfg_mountPass",rw,file_mode=0777,dir_mode=0777 //$cfg_nasIP/$cfg_dir /mnt/cfg_temp > /dev/null 2>&1
    cp /mnt/cfg_temp/$cfg_filename $shiot_configPath/$shiot_configFile > /dev/null 2>&1
    umount /mnt/cfg_temp > /dev/null 2>&1
    rm -d /mnt/cfg_temp > /dev/null 2>&1
    echo "- ${txt_0009}"
  else
    if bash handler/generate_config.sh $var_language $cfg_nasIP; then
      echo "- ${txt_0010}"
    else
      echo "- ${txt_0011}"
      exit
    fi
  fi
fi

# Start and wait for Proxmox Basic configuration if it's not already done
if [ $(cat "$shiot_configPath/helper" | grep -cw "PVE config OK") -eq 0 ]; then
  if bash bin/config_pve${pve_majorversion}.sh; then
    echo "- ${txt_0012}"
    echo "PVE config OK" >> "$shiot_configPath/helper"
  else
    echo "- ${txt_0013}"
    echo "PVE config not OK" >> "$shiot_configPath/helper"
  fi
fi

# Generate an Config Container (LXC) in Proxmox if User want it
whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_6} " "\n${txt_0014}" 20 80
yesno=$?
if [ $yesno -eq 0 ]; then
  if bash bin/generate_lxc.sh; then
    echo "- ${txt_0015}"
  fi
else
  echo "- ${txt_0016}"
fi

# Generate an Config virtual Mashines (VM) in Proxmox if User want it
whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_7} " "\n${txt_0017}" 20 80
yesno=$?
if [ $yesno -eq 0 ]; then
  if bash bin/generate_vm.sh; then
    echo "- ${txt_0018}"
  fi
else
  echo "- ${txt_0019}"
fi

# Cleanup Proxmox History
cat /dev/null > ~/.bash_history && history -c && history -w
echo "- ${txt_0020}"

exit
