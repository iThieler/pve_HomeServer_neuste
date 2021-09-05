#!/bin/bash

var_language=$1
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

if ! ls /mnt/pve/backups/dump/*_manual.*.zst 1> /dev/null 2>&1; then
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0008} " "\n${txt_1201}" 10 80
  echoLOG r "${txt_1201}"
  exit 1
fi

whiptail --yesno --yes-button " ${btn_13} " --no-button " ${btn_14} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0009} " "\n${txt_1202}?" 15 80
yesno=$?
if [ $yesno -eq 0 ]; then
  echoLOG y "${txt_1203}"
  for guest in $(ls -l /mnt/pve/backups/dump/*_manual.*.zst | awk '{print $9}' | cut -d- -f3); do
    echoLOG y "${txt_1204} >> ${wrd_0001}: ${LIGHTPURPLE}${guest}${NOCOLOR}  ${wrd_0002}: ${LIGHTPURPLE}$(pct list | grep ${guest} | awk '{print $3}')${NOCOLOR}"
    if [ $(ls -ldst /mnt/pve/backups/dump/*-${guest}-*_manual.*.zst | grep -c "tar") -eq 1 ]; then
      pct shutdown $guest --forceStop 1 --timeout 10 > /dev/null 2>&1
      if pct restore $guest /mnt/pve/backups/dump/*-${guest}-*_manual.tar.zst --storage ${ctTemplateDisk} --pool "BackupPool" --force 1 > /dev/null 2>&1; then
        echoLOG g "${txt_1206}"
      else
        echoLOG r "${txt_1207}"
      fi
      pct start $guest > /dev/null 2>&1
    elif [ $(ls -ldst /mnt/pve/backups/dump/*-${guest}-*_manual.*.zst | grep -c "vma") -eq 1 ]; then
      qm shutdown $guest --forceStop 1 --timeout 30 > /dev/null 2>&1
      if qmrestore $guest /mnt/pve/backups/dump/*-${guest}-*_manual.vma.zst --storage ${ctTemplateDisk} --pool "BackupPool" --force 1 > /dev/null 2>&1; then
        echoLOG g "${txt_1206}"
      else
        echoLOG r "${txt_1207}"
      fi
      qm start $guest > /dev/null 2>&1
    fi
  done
else
  echoLOG y "${txt_1203}"
  for guest in $(ls -l /mnt/pve/backups/dump/*_manual.*.zst | awk '{print $9}' | cut -d- -f3); do
    if [ $(ls -ldst /mnt/pve/backups/dump/*-${guest}-*_manual.*.zst | grep -c "tar") -eq 1 ]; then
      if [ $(pct list | grep -cw 100) -eq 0 ]; then
        ctID=100
      else
        ctID=100
        while [ $(pct list | grep -c $ctID ) -eq 1 ]; do
          ctID=$(( $ctID + 1 ))
        done
      fi
      if pct restore $ctID /mnt/pve/backups/dump/*-$guest-*_manual.tar.zst --storage ${ctTemplateDisk} --pool "BackupPool" --force 1 > /dev/null 2>&1; then
        hostname=$(pct list | grep $ctID | awk '{print $3}')
        pct set $ctID --hostname "${hostname}-${wrd_0021}"
        pct start $guest > /dev/null 2>&1
        echoLOG g "${txt_1206} >> ${wrd_0001}: ${LIGHTPURPLE}${guest}${NOCOLOR}  ${wrd_0002}: ${LIGHTPURPLE}${hostname}-${wrd_0021}${NOCOLOR}"
      else
        echoLOG r "${txt_1207}"
      fi
    elif [ $(ls -ldst /mnt/pve/backups/dump/*-${guest}-*_manual.*.zst | grep -c "vma") -eq 1 ]; then
      if [ $(qm list | grep -cw 200) -eq 0 ]; then
        vmID=200
      else
        vmID=200
        while [ $(qm list | grep -c $vmID ) -eq 1 ]; do
          vmID=$(( $vmID + 1 ))
        done
      fi
      if qmrestore $wmID /mnt/pve/backups/dump/*-$guest-*_manual.vma.zst --storage ${ctTemplateDisk} --pool "BackupPool" --force 1 > /dev/null 2>&1; then
        hostname=$(qm list | grep $vmID | awk '{print $2}')
        qm set $wmID --name "${hostname}-${wrd_0021}"
        qm start $guest > /dev/null 2>&1
        echoLOG g "${txt_1206} >> ${wrd_0001}: ${LIGHTPURPLE}${guest}${NOCOLOR}  ${wrd_0002}: ${LIGHTPURPLE}${hostname}-${wrd_0021}${NOCOLOR}"
      else
        echoLOG r "${txt_1207}"
      fi
    fi
  done
fi

if [ $(cat /opt/smarthome-iot_net/shiot_log.txt | grep -cw "${txt_1207}") -eq 0 ]; then exit 0; else exit 1; fi
