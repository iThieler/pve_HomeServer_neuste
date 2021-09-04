#!/bin/bash

var_language=$1
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

if [ -d "/mnt/pve/backups/dump" ]; then
  if [ $(ls /mnt/pve/backups/dump/*-lxc-*_manual.*.zst | grep -c "_manual.") - ge 0 ]; then
    NEWT_COLORS='
        window=black,red
        border=white,red
        textbox=white,red
        button=black,yellow
      ' \
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0008} " "\n${txt_1201}" 10 80
    echoLOG r "${txt_1201}"
  fi
else
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0008} " "\n${txt_1201}" 10 80
  echoLOG r "${txt_1201}"
fi

whiptail --yesno --yes-button " ${btn_13} " --no-button " ${btn_14} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0009} " "\n${txt_1202}?" 15 80
yesno=$?
if [ $yesno -eq 0 ]; then
  echoLOG y "${txt_1203}"
  for guest in $(ls -ldst /mnt/pve/backups/dump/*_manual.*.zst | awk '{print $10}' | cut -d- -f3); do
    if [ $(pct list | grep -c $guest) -eq 1 ]; then
      echoLOG y "${txt_1204} >> ${wrd_0001}: ${LIGHTPURPLE}$guest${NOCOLOR}  ${wrd_0002}: ${LIGHTPURPLE}$(pct list | grep $guest | awk '{print $2}')${NOCOLOR}"
      if bash "$script_path/handler/delete_lxc.sh" $var_language $guest; then
        echoLOG g "${1205}"
        if [ $(pct restore $guest /mnt/pve/backups/dump/*-$guest-*_manual.tar.zst -storage ${ctTemplateDisk}) -eq 0 ]; then
          echoLOG g "${1206}"
        else
          echoLOG r "${1207}"
        fi
      else
        echoLOG r "${txt_1208}"
      fi
    elif [ $(pct list | grep -c $guest) -eq 0 ]; then
      if [ $(pct restore $guest /mnt/pve/backups/dump/*-$guest-*_manual.vma.zst -storage ${ctTemplateDisk}) -eq 0 ]; then
        echoLOG g "${1206}"
      else
        echoLOG r "${1207}"
      fi
    elif [ $(qm list | grep -c $guest) -eq 1 ]; then
      echoLOG y "${txt_1204} >> ${wrd_0001}: ${LIGHTPURPLE}$guest${NOCOLOR}  ${wrd_0002}: ${LIGHTPURPLE}$(qm list | grep $guest | awk '{print $2}')${NOCOLOR}"
      if bash "$script_path/handler/delete_vm.sh" $var_language $guest; then
        echoLOG g "${1205}"
        if [ $(pct restore $guest /mnt/pve/backups/dump/*-$guest-*_manual.vma.zst -storage ${ctTemplateDisk}) -eq 0 ]; then
          echoLOG g "${1206}"
        else
          echoLOG r "${1207}"
        fi
      else
        echoLOG r "${txt_1208}"
      fi
    fi
    elif [ $(qm list | grep -c $guest) -eq 0 ]; then
      if [ $(pct restore $guest /mnt/pve/backups/dump/*-$guest-*_manual.vma.zst -storage ${ctTemplateDisk}) -eq 0 ]; then
        echoLOG g "${1206}"
      else
        echoLOG r "${1207}"
      fi
    fi
  done
else
  echoLOG y "${txt_1203}"
  for guest in $(ls -ldst /mnt/pve/backups/dump/*_manual.*.zst | awk '{print $10}' | cut -d- -f3); do
    if [ $(ls -ldst /mnt/pve/backups/dump/*-$guest-*_manual.*.zst | grep -c "tar") -eq 1 ]; then
      if [ $(pct list | grep -cw 100) -eq 0 ]; then
        ctID=100
      else
        ctID=100
        while [ $(pct list | grep -c $ctID ) -eq 1 ]; do
          ctID=$(( $ctID + 1 ))
        done
      fi
      pct restore $ctID /mnt/pve/backups/dump/*-$guest-*_manual.tar.zst -storage ${ctTemplateDisk}
    elif [ $(ls -ldst /mnt/pve/backups/dump/*-$guest-*_manual.*.zst | grep -c "vma") -eq 1 ]; then
      if [ $(qm list | grep -cw 200) -eq 0 ]; then
        vmID=200
      else
        vmID=200
        while [ $(qm list | grep -c $vmID ) -eq 1 ]; do
          vmID=$(( $vmID + 1 ))
        done
      fi
      qmrestore $wmID /mnt/pve/backups/dump/*-$guest-*_manual.vma.zst -storage ${ctTemplateDisk}
    fi
  done
fi

if [ $(cat /opt/smarthome-iot_net/shiot_log.txt | grep -cw "${1207}") -eq 0 ]; then exit 0; else exit 1; fi
