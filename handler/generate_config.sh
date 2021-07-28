#!/bin/bash

source "bin/variables.sh"
source "handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"

var_language="$1"
var_nasip="$2"

# Network Variables
gatewayIP=$(ip r | grep default | cut -d" " -f3)
pve_ip=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1)
cidr=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f2)
networkIP=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f1,2,3)
publicIP=$(dig @resolver4.opendns.com myip.opendns.com +short)
pve_fqdn=$(hostname -f)
pve_hostname=$(hostname)

# Hardware Variables
rootDisk=$(lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"' | cut -d' ' -f2 | cut -d\" -f2 | sed 's#[0-9]*$##')

# search second Harddisk and check if is SSD
if [[ $(cat /sys/block/$(lsblk -nd --output NAME | grep "s" | sed "s#$rootDisk##" | sed ':M;N;$!bM;s#\n##g')/queue/rotational) -eq 0 ]]; then
  secondDisk=$(lsblk -nd --output NAME | grep "s" | sed "s#$rootDisk##" | sed ':M;N;$!bM;s#\n##g')
  ctTemplateDisk="data"
else
  ctTemplateDisk="local"
fi

# Proxmox Variables
clusterfileFW="/etc/pve/firewall/cluster.fw"
hostfileFW="/etc/pve/nodes/$pve_hostname/host.fw"
pve_timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
pve_osname=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d= -f2)

# ask User for Script Language
if [ -z "$var_language" ]; then
  var_language=$(whiptail --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --menu "" 20 80 10 "${lng[@]}" 3>&1 1>&2 2>&3)
  source <(curl -sSL $configURL/lang/$var_language.lang)
fi

# config Netrobot
if [ -z "$var_robotname" ]; then
  var_robotname=$(whiptail --inputbox --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_exit} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_netrobot}" "\n${lng_ask_netrobotname}" ${ri} ${c} netrobot 3>&1 1>&2 2>&3)
  if [ -z "$var_robotpw" ]; then
    var_robotpw=$(whiptail --passwordbox --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_cancel} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_password}" "\n${lng_txt_netrobot_password}\n\n${lng_ask_netrobot_password}" ${ri} ${c} 3>&1 1>&2 2>&3)
    if [[ $var_robotpw = "" ]]; then
      var_robotpw=$(generatePassword 26)
    fi
  fi
fi

# config VLAN
if [ -z "$var_vlan" ]; then
  whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_vlan}" "\n${lng_ask_vlan}" ${ri} ${c}
  yesno=$?
  if [ $yesno -eq 0 ]; then
    var_servervlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_vlan}" "\n${lng_ask_vlan_server}" ${ri} ${c} 100 3>&1 1>&2 2>&3)
    var_smarthomevlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_vlan}" "\n${lng_ask_vlan_smarthome}" ${ri} ${c} 200 3>&1 1>&2 2>&3)
    var_guestvlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_vlan}" "\n${lng_ask_vlan_guest}" ${ri} ${c} 300 3>&1 1>&2 2>&3)
  fi
fi

# config SMTP server for email notification
if [ -z "$var_rootmail" ]; then
  var_rootmail=$(whiptail --inputbox --ok-button " ${lng_btn_ok} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_mailconfiguration}" --title "${lng_wrd_mailserver}" "\n${lng_ask_mail_root_address}" ${ri} ${c} $(pveum user list | grep "root@pam" | awk '{print $5}') 3>&1 1>&2 2>&3)
fi
if [ -z "$var_mailserver" ]; then
  var_mailserver=$(whiptail --inputbox --ok-button " ${lng_btn_ok} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_mailconfiguration}" --title "${lng_wrd_mailserver}" "\n${lng_ask_mail_server}" ${ri} ${c} 3>&1 1>&2 2>&3)
fi
if [ -z "$var_mailport" ]; then
  var_mailport=$(whiptail --inputbox --ok-button " ${lng_btn_ok} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_mailconfiguration}" --title "${lng_wrd_mailserver}" "\n${lng_ask_mail_server_port}" ${ri} ${c} 587 3>&1 1>&2 2>&3)
fi
if [ -z "$var_mailusername" ]; then
  var_mailusername=$(whiptail --inputbox --ok-button " ${lng_btn_ok} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_mailconfiguration}" --title "${lng_wrd_mailserver}" "\n${lng_ask_mail_server_user}" ${ri} ${c} 3>&1 1>&2 2>&3)
fi
if [ -z "$var_mailpassword" ]; then
  var_mailpassword=$(whiptail --passwordbox --ok-button " ${lng_btn_ok} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_mailconfiguration}" --title "${lng_wrd_mailserver}" "\n${lng_ask_mail_server_password}" ${ri} ${c} 3>&1 1>&2 2>&3)
fi
if [ -z "$var_senderaddress" ]; then
  var_senderaddress=$(whiptail --inputbox --ok-button " ${lng_btn_ok} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_mailconfiguration}" --title "${lng_wrd_mailserver}" "\n${lng_ask_mail_sender}" ${ri} ${c} "notify@$(echo "$var_rootmail" | cut -d\@ -f2)" 3>&1 1>&2 2>&3)
fi
if [ -z "$var_mailtls" ]; then
  whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_mailconfiguration}" --title "${lng_wrd_mailserver}" "\n${lng_ask_mail_tls}" ${ri} ${c}
  yesno=$?
  if [ $yesno -eq 0 ]; then
    var_mailtls=yes
  else
    var_mailtls=no
  fi
fi

# config NAS
if [ -z "$var_nasip" ]; then
  whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_nas} ${lng_wrd_configuration}" --title "${lng_wrd_nas}" "${lng_ask_nas_exist}" ${r} ${c}
  yesno=$?
  if [ $yesno -eq 0 ]; then
    while ! pingIP $var_nasip; do
      var_nasip=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title "NAS" "\nWie lautet die IP-Adresse deiner NAS?" 10 80 $networkIP. 3>&1 1>&2 2>&3)
    done
  fi
fi

# create config File
cat <<EOF > $shiot_configPath/$shiot_configFile
#!/bin/sh
# NOTICE: Backup Proxmox Configuration Script from SmartHome-IoT.net
# Created on $(date # : <<-- this will be evaluated before cat;)

# Proxmox-/System configuration
pve_ip=$pve_ip
pve_fqdn=$pve_fqdn
pve_hostname=$pve_hostname
pve_osname=$pve_osname
pve_timezone=$pve_timezone
var_language=$var_language

# Gateway configuration
gatewayIP=$gatewayIP
networkIP=$networkIP
cidr=$cidr
var_servervlan=$var_servervlan
var_smarthomevlan=$var_smarthomevlan
var_guestvlan=$var_guestvlan

# Firewall configuration
firewallConfiguration=$firewallConfiguration
clusterfileFW=$clusterfileFW
hostfileFW=$hostfileFW

# SMTP-Server configuration
emailConfiguration=$emailConfiguration
var_rootmail=$var_rootmail
var_mailserver=$var_mailserver
var_mailport=$var_mailport
var_mailusername=$var_mailusername
var_mailpassword=\"\"
var_senderaddress=$var_senderaddress
var_mailtls=$var_mailtls
sendmail=$sendmail
# HDD-/Storage configuration
sysHDDConfiguration=$sysHDDConfiguration      \0043 DO NOT CHANGE THIS!!!
rootDisk=$rootDisk
secHDDConfiguration=$secHDDConfiguration
secondDisk=$secondDisk
ctTemplateDisk=$ctTemplateDisk

# Netrobot configuration
var_robotname=$var_robotname
var_robotpw=\"\"

# NAS configuration
nasConfiguration=$nasConfiguration
var_nasip=$var_nasip
var_synologynas=$var_synologynas

# OctoPi configuration
var_octoip=$var_octoip

EOF