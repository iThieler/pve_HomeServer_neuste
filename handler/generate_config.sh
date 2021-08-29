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
    var_nasip=$(whiptail --inputbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt}?" 10 80 $networkIP. 3>&1 1>&2 2>&3)
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
    if [ -z "$var_servervlan" ]; then
      var_servervlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0806}" 10 80 100 3>&1 1>&2 2>&3)
    fi
    if [ -z "$var_smarthomevlan" ]; then
      var_smarthomevlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0807}" 10 80 200 3>&1 1>&2 2>&3)
    fi
    if [ -z "$var_guestvlan" ]; then
      var_guestvlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0007} " "\n${txt_0808}" 10 80 300 3>&1 1>&2 2>&3)
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
if [[ $(cat /sys/block/$(lsblk -nd --output NAME | grep "s" | sed "s#$rootDisk##" | sed ':M;N;$!bM;s#\n##g')/queue/rotational) -eq 0 ]]; then
  secondDisk=$(lsblk -nd --output NAME | grep "s" | sed "s#$rootDisk##" | sed ':M;N;$!bM;s#\n##g')
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
echo -e "var_servervlan=\"$var_servervlan\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_smarthomevlan=\"$var_smarthomevlan\"" >> $shiot_configPath/$shiot_configFile
echo -e "var_guestvlan=\"$var_guestvlan\"" >> $shiot_configPath/$shiot_configFile

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

exit 0
