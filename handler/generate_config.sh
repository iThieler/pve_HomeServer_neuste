#!/bin/bash

var_language=$1
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
if [ -f "$shiot_configPath/$shiot_configFile" ]; then
  source "$shiot_configPath/$shiot_configFile"
fi
source "$script_path/language/$var_language.sh"

function setNAS() {
  i=0
  repeat=$1
  while ! pingIP $var_nasip && [ $i != 6 ]; do
    if [ $i -ge 1 ] || [ -n "$repeat" ]; then
      txt="${txt_0817}\n\n!!! ${txt_0818} !!!"
    else
      txt="${txt_0817}"
    fi
    var_nasip=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt}" 10 80 $networkIP. 3>&1 1>&2 2>&3)
    i=$(( $i + 1 ))
  done

  if [ $i -lt 6 ]; then
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0819}\n\nbackups\nmedia" 10 80
  else
    NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0820}\n\n${txt_0821}" 10 80
    yesno=$?
    if [ $yesno -eq 0 ]; then setNAS 1; fi
  fi

  if [ -n "$var_nasip" ]; then
    whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0825}" 10 80
    yesno=$?
    if [ $yesno -eq 0 ]; then var_synologynas=true; fi
  fi
}

# config Netrobot
if [ -z "$var_robotname" ]; then
  var_robotname=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0801}" 10 80 netrobot 3>&1 1>&2 2>&3)
  if [ -z "$var_robotpw" ]; then
    var_robotpw=$(whiptail --passwordbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0802}\n${txt_0803}" 10 80 3>&1 1>&2 2>&3)
    if [[ $var_robotpw = "" ]]; then
      var_robotpw=$(generatePassword 26)
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title "${tit_0007}" "\n${txt_0804}\n\n${wrd_0003}: ${var_robotname}\n${wrd_0004}: ${var_robotpw}" 10 80
    fi
  fi
fi

# config VLAN
if [ -z "$var_vlan" ]; then
  whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0805}" 10 80
  yesno=$?
  if [ $yesno -eq 0 ]; then
    if [ -z "$var_servervlanid" ]; then
      var_servervlanid=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0806}" 10 80 10 3>&1 1>&2 2>&3)
      var_servervlangw=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0826}" 10 80 "$gatewayIP/$cidr" 3>&1 1>&2 2>&3)
    fi
    if [ -z "$var_smarthomevlanid" ]; then
      var_smarthomevlanid=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0807}" 10 80 20 3>&1 1>&2 2>&3)
      var_smarthomevlangw=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0826}" 10 80 "$(echo $networkIP | cut -d. -f1,2).$var_smarthomevlanid.1/24" 3>&1 1>&2 2>&3)
      smarthomenetadapter=$(find /sys/class/net -type l -not -lname '*virtual*' -printf '%f\n' | sed "s|${prinetadapter}||" | sed '/^$/d')
    fi
    if [ -z "$var_dhcpvlanid" ]; then
      var_dhcpvlanid=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0827}" 10 80 30 3>&1 1>&2 2>&3)
      var_dhcpvlangw=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0826}" 10 80 "$(echo $networkIP | cut -d. -f1,2).$var_dhcpvlanid.1/24" 3>&1 1>&2 2>&3)
    fi
    if [ -z "$var_guestvlanid" ]; then
      var_guestvlanid=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0808}" 10 80 100 3>&1 1>&2 2>&3)
      var_guestvlangw=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0826}" 10 80  "$(echo $networkIP | cut -d. -f1,2).$var_guestvlanid.1/24" 3>&1 1>&2 2>&3)
    fi
  fi
fi

# config SMTP server for email notification
if [ -z "$var_rootmail" ]; then
  var_rootmail=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0809}" 10 80 $(pveum user list | grep "root@pam" | awk '{print $5}') 3>&1 1>&2 2>&3)
fi
if [ -z "$var_mailserver" ]; then
  var_mailserver=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0810}" 10 80 smtp.$(echo "$var_rootmail" | cut -d\@ -f2) 3>&1 1>&2 2>&3)
fi
if [ -z "$var_mailport" ]; then
  var_mailport=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0811}" 10 80 587 3>&1 1>&2 2>&3)
fi
if [ -z "$var_mailtls" ]; then
  whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0812}" 10 80
  yesno=$?
  if [ $yesno -eq 0 ]; then
    var_mailtls=yes
  else
    var_mailtls=no
  fi
fi
if [ -z "$var_mailusername" ]; then
  var_mailusername=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0813}" 10 80 $(pveum user list | grep "root@pam" | awk '{print $5}') 3>&1 1>&2 2>&3)
fi
if [ -z "$var_mailpassword" ]; then
  var_mailpassword=$(whiptail --passwordbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0814}" 10 80 3>&1 1>&2 2>&3)
fi
if [ -z "$var_senderaddress" ]; then
  var_senderaddress=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0815}" 10 80 "notify@$(echo "$var_rootmail" | cut -d\@ -f2)" 3>&1 1>&2 2>&3)
fi

# config NAS
if [ -z "$var_nasip" ]; then
  whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "${txt_0816}" 10 80
  yesno=$?
  if [ $yesno -eq 0 ]; then
    setNAS
  fi
fi

# config/search second Harddisk and check if is SSD
if [[ $(cat /sys/block/$(lsblk -nd --output NAME | grep "s" | sed "s|$rootDisk||" | sed ':M;N;$!bM;s|\n||g')/queue/rotational) -eq 0 ]]; then
  secondDisk=$(lsblk -nd --output NAME | grep "s" | sed "s|$rootDisk||" | sed ':M;N;$!bM;s|\n||g')
  ctTemplateDisk="data"
else
  ctTemplateDisk="local"
fi

# ask the user if the passwords should be saved in the configuration file
whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0822}" 10 80
pws=$?

# create config File
echo -e "\0043\0041/bin/bash" > $shiot_configPath/$shiot_configFile
echo -e "\0043 NOTICE: Backup Proxmox Configuration Script from SmartHome-IoT.net" >> $shiot_configPath/$shiot_configFile
echo -e "\0043 Created on $(date)" >> $shiot_configPath/$shiot_configFile
echo -e "\n\0043 General configuration" >> $shiot_configPath/$shiot_configFile
echo -e "var_language=\"$var_language\"" >> $shiot_configPath/$shiot_configFile
echo -e "\n\0043 Network configuration" >> $shiot_configPath/$shiot_configFile
echo -e "prinetadapter=\"$prinetadapter\"" >> $shiot_configPath/$shiot_configFile
echo -e "smarthomenetadapter=\"$smarthomenetadapter\"" >> $shiot_configPath/$shiot_configFile
echo -e "pve_ip=\"$pve_ip\"" >> $shiot_configPath/$shiot_configFile
echo -e "pve_gw=\"$gatewayIP\"" >> $shiot_configPath/$shiot_configFile
echo -e "pve_ip_smarthome=\"$(echo $var_servervlangw | cut -d. -f1,2,3).$(echo ${pve_ip} | cut -d. -f4)\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_servervlanid=\"$var_servervlanid\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_servervlangw=\"$var_servervlangw\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_smarthomevlanid=\"$var_smarthomevlanid\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_smarthomevlangw=\"$var_smarthomevlangw\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_dhcpvlanid=\"$var_dhcpvlanid\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_dhcpvlangw=\"$var_dhcpvlangw\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_guestvlanid=\"$var_guestvlanid\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_guestvlangw=\"$var_guestvlangw\"" >> $shiot_configPath/$shiot_configFile

echo -e "\n\0043 Netrobot configuration" >> $shiot_configPath/$shiot_configFile
echo -e "var_robotname=\"$var_robotname\"" >> $shiot_configPath/$shiot_configFile
if [ $pws -eq 0 ]; then
  echo -e "var_robotpw=\"$var_robotpw\"" >> $shiot_configPath/$shiot_configFile
fi

echo -e "\n\0043 Mailserver configuration" >> $shiot_configPath/$shiot_configFile
echo -e "var_rootmail=\"$var_rootmail\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_mailserver=\"$var_mailserver\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_mailport=\"$var_mailport\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_mailtls=\"$var_mailtls\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_mailusername=\"$var_mailusername\"" >> $shiot_configPath/$shiot_configFile
if [ $pws -eq 0 ]; then
  echo -e "var_mailpassword=\"$var_mailpassword\"" >> $shiot_configPath/$shiot_configFile
fi
echo -e "var_senderaddress=\"$var_senderaddress\"" >> $shiot_configPath/$shiot_configFile

echo -e "\n\0043 NAS configuration" >> $shiot_configPath/$shiot_configFile
echo -e "var_nasip=\"$var_nasip\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_synologynas=\"$var_synologynas\"" >> $shiot_configPath/$shiot_configFile

echo -e "\n\0043 Host-/ System-/ Proxmox variables" >> $shiot_configPath/$shiot_configFile
echo -e "ctTemplateDisk=\"$ctTemplateDisk\"" >> $shiot_configPath/$shiot_configFile

if [ -f "$shiot_configPath/$shiot_configFile" ]; then
  echoLOG g "${txt_0823}"
else
  echoLOG r "${txt_0824}"
fi

exit 0
