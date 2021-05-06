#!/bin/bash

#################### Required software ####################

pve_Standardsoftware="parted smartmontools libsasl2-modules lxc-pve"  # Software that is installed afterwards on the server host

##################### Script Variables ####################

# Divide by two so the dialogs take up half of the screen, which looks nice.
r=$(( rows / 2 ))
ri=$(( rows / 2 ))
c=$(( columns / 2 ))
# Unless the screen is tiny
r=$(( r < 20 ? 20 : r ))
ri=$(( r < 10 ? 10 : r ))
c=$(( c < 80 ? 80 : c ))

# check if Variable is valid URL
regexURL='^(https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'

##################### Script Variables ####################

# Network Variables
gatewayIP=$(ip r | grep default | cut -d" " -f3)
pveIP=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1)
cidr=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f2)
networkIP=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f1,2,3)
publicIP=$(dig @resolver4.opendns.com myip.opendns.com +short)
fqdn=$(hostname -f)
hostname=$(hostname)

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
hostfileFW="/etc/pve/nodes/$hostname/host.fw"
timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
osname=buster

# SmartHome-IoT.net Github scripts in Variables
configURL="https://raw.githubusercontent.com/shiot/pve_HomeServer/master"

# check if Script runs FirstTime
configFile="/root/.cfg_shiot"
recoverConfig=false

##################### Selection menus #####################

# Language selctor
lng=(\
  "${lng_wrd_de_short}" "      ${lng_wrd_de_long}" \
  "${lng_wrd_en_short}" "      ${lng_wrd_en_long}" \
)

# Gateway selector
gw=(\
  "1" "  Ubiquiti/UniFi DreamMachine Pro ${lng_wrd_or} CloudKey               " off \
  "2" "  AVM FRITZ!Box" off \
  "0" "  ${lng_txt_another_manufacturer}" off \
)

######################## Functions ########################

function chooseLanguage() {
# ask User for Script Language
  var_language=$(whiptail --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --menu "" ${r} ${c} 10 "${lng[@]}" 3>&1 1>&2 2>&3)
  source <(curl -sSL $configURL/lang/$var_language.lang)
}

function generatePassword() {
# Function generates a random secure password
  chars=({0..9} {a..z} {A..Z} "_" "%" "&" "+" "-")
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

function generateAPIKey() {
# Function generates a random API-Key
  chars=({0..9} {a..f})
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

function cleanupHistory() {
# Function clean the Shell History
  cat /dev/null > ~/.bash_history && history -c && history -w
}

function checkConfigFile() {
# Function Check if this script run the first time
  if [ -f "${configFile}" ]; then
    NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_txt_recover_config}" --title "${lng_wrd_config_file}" "\n${lng_txt_config_done}\n\n${lng_ask_add_lxc}" ${r} ${c}
      yesno=$?
      if [ $yesno -eq 0 ]; then
        curl -sSL https://lxc.config.shiot.de | bash
        exit
      else
        exit
      fi
  else
    whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_txt_recover_config}" --title "${lng_wrd_config_file}" "${lng_ask_recover_config}" ${r} ${c}
    yesno=$?
    if [ $yesno -eq 0 ]; then
      mkdir /mnt/cfg_temp
      cfg_mountIP=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_txt_recover_config}" --title "${lng_wrd_config_file}" "\n${lng_ask_ip_nas}" ${ri} ${c} $networkIP.20 3>&1 1>&2 2>&3)
      cfg_filename=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_txt_recover_config}" --title "${lng_wrd_config_file}" "\n${lng_ask_config_filename}" ${ri} ${c} Proxmox_Configuration.txt 3>&1 1>&2 2>&3)
      cfg_mountUser=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_txt_recover_config}" --title "${lng_wrd_config_file}" "\n${lng_ask_username}" ${ri} ${c} netrobot 3>&1 1>&2 2>&3)
      cfg_mountPass=$(whiptail --passwordbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_txt_recover_config}" --title "${lng_wrd_config_file}" "\n${lng_ask_password}" ${ri} ${c} 3>&1 1>&2 2>&3)
      cfg_Summary="
        ${lng_wrd_ipadress}: $cfg_mountIP
        ${lng_wrd_filename}: $cfg_filename
        ${lng_wrd_username}: $cfg_mountUser
        ${lng_wrd_password}: $cfg_mountPass
        "
      whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_txt_recover_config}" --title "${lng_wrd_config_file}" "\n${lng_txt_provided_informations}\n$cfg_Summary\n${lng_ask_all_correct}" ${r} ${c}
      yesno=$?
      if [ $yesno -eq 0 ]; then
        mkdir -p /mnt/cfg_temp
        mount -t cifs -o user="$cfg_mountUser",password="$cfg_mountPass",rw,file_mode=0777,dir_mode=0777 //$cfg_mountIP/backups /mnt/cfg_temp
        cp /mnt/cfg_temp/$cfg_filename $configFile
        umount /mnt/cfg_temp
        rm -d /mnt/cfg_temp
        recoverConfig=true
      else
        NEWT_COLORS='
          window=,red
          border=white,red
          textbox=white,red
          button=black,yellow
        ' \
        whiptail --yesno --yes-button " ${lng_btn_retry} " --nocancel --no-button " ${lng_btn_exit} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_txt_recover_config}" --title "${lng_wrd_config_file}" "\n${lng_txt_no_changes_to_server} ${lng_txt_perform_server_config_again}" ${r} ${c}
        yesno=$?
        if [[ $yesno == 1 ]]; then
          checkFirstRun
        else
          exit
        fi
      fi
    else
      return 1
    fi
  fi
}

function informUser() {
# Function give some Informations to the User
  whiptail --msgbox --ok-button " ${lng_btn_ok} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_welcome}" --title "${lng_wrd_welcome}" "\n${lng_txt_welcome_sysdisc}\n\n${lng_txt_welcome_nas}\n\n${lng_txt_welcome_raid}" ${r} ${c}
  whiptail --msgbox --ok-button " ${lng_btn_ok} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_welcome}" --title "${lng_wrd_introduction}" "\n${lng_txt_introduction_text}\n\n${lng_txt_fresh_install}" ${r} ${c}
  whiptail --msgbox --ok-button " ${lng_btn_ok} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_welcome}" --title "${lng_wrd_netrobot}" "\n${lng_txt_netrobot}" ${r} ${c}
  whiptail --msgbox --ok-button " ${lng_btn_ok} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_welcome}" --title "${lng_wrd_password}" "\n${lng_txt_secure_password}\n\n${lng_txt_autogenerate_password}: $(generatePassword 20)\n\n${lng_txt_check_password_security}" ${r} ${c}
}

function configNetrobot() {
# Function ask User for Netrobot Configuration
  if [ -z "$var_robotname" ]; then
    var_robotname=$(whiptail --inputbox --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_exit} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_netrobot}" "\n${lng_ask_netrobotname}" ${ri} ${c} netrobot 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 1 ]; then
      NEWT_COLORS='
        window=,red
        border=white,red
        textbox=white,red
        button=black,yellow
      ' \
      whiptail --msgbox --ok-button " ${lng_btn_ok} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_abort}" "\n${lng_txt_no_changes_to_server} ${lng_txt_perform_server_config_again}" ${r} ${c}
      exit 1
    fi
  fi
  var_robotpw=$(whiptail --passwordbox --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_cancel} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_password}" "\n${lng_txt_netrobot_password}\n\n${lng_ask_netrobot_password}" ${ri} ${c} 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 1 ]; then
    NEWT_COLORS='
      window=,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
    whiptail --msgbox --ok-button " ${lng_btn_ok} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_abort}" "\n${lng_txt_no_changes_to_server} ${lng_txt_perform_server_config_again}" ${r} ${c}
    exit 1
  fi
  if [[ $var_robotpw = "" ]]; then
    var_robotpw=$(generatePassword 26)
  fi
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_password}" "\n${lng_txt_natrobot_paaswort_summary}\n\n${lng_wrd_username}: ${var_robotname}\n${lng_wrd_password}: ${var_robotpw}" ${r} ${c}
}

function configGateway() {
# Function ask User for Gateway Manufacturer
  if [ -z "$var_gwmanufacturer" ]; then
    var_gwmanufacturer=$(whiptail --radiolist --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_cancel} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_manufacturer}" "\n${lng_ask_gateway_manufacturer}" ${ri} ${c} 10 "${gw[@]}" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 1 ]; then
      NEWT_COLORS='
        window=,red
        border=white,red
        textbox=white,red
        button=black,yellow
      ' \
      whiptail --msgbox --ok-button " ${lng_btn_ok} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_abort}" "\n${lng_txt_no_changes_to_server} ${lng_txt_perform_server_config_again}" ${r} ${c}
      exit 1
    fi
    if [ $var_gwmanufacturer -eq 1]; then
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_vlan}" "${lng_txt_vlan_info}" ${r} ${c}
      whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_vlan}" "\n${lng_ask_vlan}" ${ri} ${c}
      yesno=$?
      if [ $yesno -eq 0 ]; then
        var_servervlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_vlan}" "\n${lng_ask_vlan_server}" ${ri} ${c} 100 3>&1 1>&2 2>&3)
        var_smarthomevlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_vlan}" "\n${lng_ask_vlan_smarthome}" ${ri} ${c} 200 3>&1 1>&2 2>&3)
        var_guestvlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_vlan}" "\n${lng_ask_vlan_guest}" ${ri} ${c} 300 3>&1 1>&2 2>&3)
      fi
    fi
  fi
}

function configSMTPServer() {
# Function ask User for SMTP-Server-Configuration
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
}

function configNAS() {
# Function ask User if NAS exists in Network and bind to Proxmox as Backup Storage
  if [ -z "$var_nasip" ]; then
    whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_nas} ${lng_wrd_configuration}" --title "${lng_wrd_nas}" "${lng_ask_nas_exist}" ${r} ${c}
    yesno=$?
    if [ $yesno -eq 0 ]; then
      if [ -z "$var_nasip" ]; then
        var_iptocheck=$(whiptail --inputbox --ok-button " ${lng_btn_ok} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_nas} ${lng_wrd_configuration}" --title "${lng_wrd_nas}" "${lng_ask_ip_nas}" ${ri} ${c} 3>&1 1>&2 2>&3)
        if ping -c 1 $var_iptocheck &> /dev/null; then
          var_nasip=$var_iptocheck
          whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_nas} ${lng_wrd_configuration}" --title "${lng_wrd_nas}" "${lng_ask_nas_synology}" ${ri} ${c}
          yesno=$?
          if [[ $yesno == 1 ]]; then
            var_synologynas=true
          else
            var_synologynas=false
          fi
          whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_nas} ${lng_wrd_configuration}" --title "${lng_wrd_nas}" "${lng_txt_nas_folder}\n\nbackups\nmedia\n\n${lng_ask_nas_folder_exist}" ${r} ${c}
          yesno=$?
          if [[ $yesno == 0 ]]; then
            if [ $(echo "${var_robotpw}" | smbclient -L ${var_nasip} -W . -U ${var_robotname} | grep -cw "backups") -eq 0 ] && [ $(echo "${var_robotpw}" | smbclient -L ${var_nasip} -W . -U ${var_robotname} | grep -cw "media") -eq 0 ]; then
              NEWT_COLORS='
                window=,red
                border=white,red
                textbox=white,red
                button=black,yellow
              ' \
              whiptail --msgbox --ok-button " ${lng_btn_ok} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_nas} ${lng_wrd_configuration}" --title "${lng_wrd_nas}" "${lng_txt_no_nas_folder_found}\n\n${lng_txt_no_nas_mount}" ${r} ${c}
              var_nasip=""
            fi
          else
            NEWT_COLORS='
              window=,red
              border=white,red
              textbox=white,red
              button=black,yellow
            ' \
            whiptail --msgbox --ok-button " ${lng_btn_ok} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_nas} ${lng_wrd_configuration}" --title "${lng_wrd_nas}" "${lng_txt_no_nas_folder}\n\n${lng_txt_no_nas_mount}" ${r} ${c}
            var_nasip=""
          fi
        else
          NEWT_COLORS='
            window=,red
            border=white,red
            textbox=white,red
            button=black,yellow
          ' \
          whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_nas} ${lng_wrd_configuration}" --title "${lng_wrd_nas}" "${lng_txt_ip_unreachable} ${lng_ask_device_connected} ${lng_ask_ip_correct}" ${r} ${c}
          yesno=$?
          if [ $yesno -eq 0 ]; then
            var_nasip=""
            configNAS
          else
            var_nasip=""
          fi
        fi
      fi
    fi
  fi
}

function mountNASAfterConfig() {
  configNAS
  if [ -z $nasConfiguration ] || ! $nasConfiguration || $recoverConfig; then
  # Function mounts, if specified, the NAS as backup drive in Proxmox and makes it available to the containers as backup and media drive
    if [ -n "$var_nasip" ]; then
      pvesm add cifs backups --server "$var_nasip" --share "backups" --username "$var_robotname" --password "$var_robotpw" --content backup
      pvesh create /pools --poolid BackupPool --comment "${lng_txt_comment_backuppool}"
      echo "0 3 * * *   root   vzdump --compress zstd --mailto root --mailnotification always --exclude-path /mnt/ --exclude-path /media/ --mode snapshot --quiet 1 --pool BackupPool --maxfiles 6 --storage backups" >> /etc/cron.d/vzdump
    fi
    nasConfiguration=true
  fi
}

function configOctopi() {
# Function asks user if there is a 3D printer on the network and he wants to create a backup script for OctoPi
  if [ -z $var_octoip ]; then
    whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - OctoPi ${lng_wrd_configuration}" --title "${lng_wrd_octopi}" "BEFINDET SICH EIN 3D-DRUCKER DERVON EINEM OCTOPI GESTEUERT WIRD IN DEINEM NETZWERK?" ${r} ${c}
    yesno=$?
    if [ $yesno -eq 0 ]; then
      var_iptocheck=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - OctoPi ${lng_wrd_configuration}" --title "${lng_wrd_octopi}" "WIE LAUTET DIE IP-ADRESSE UNTER DER DEIN OCTOPI ERREICHBAR IST?" ${r} ${c} 3>&1 1>&2 2>&3)
      if ping -c 1 $var_iptocheck &> /dev/null; then
        var_octoip=$var_iptocheck
        whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - OctoPi ${lng_wrd_configuration}" --title "${lng_wrd_octopi}" "SOLL EIN BACKUPSKRIPT ERSTELLT WERDEN, WELCHES DU AUF DEINEN OCTOPI LADEN KANNST? BACKUPS WERDEN IM BACKUPVERZEICHNIS DEINER NAS ERSTELLT." ${r} ${c}
        yesno=$?
        if [ $yesno -eq 0 ]; then
          var_octoUser=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - OctoPi ${lng_wrd_configuration}" --title "${lng_wrd_octopi}" "WIE LAUTET DER BENUTZERNAME UNTER DEM DER OCTOPI-DIENST AUSGEFÜHRT WIRD?" ${r} ${c} 3>&1 1>&2 2>&3)
          var_octoCron=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - OctoPi ${lng_wrd_configuration}" --title "${lng_wrd_octopi}" "ZU WELCHEM ZEITPUNKT SOLL DAS BACKUPSKRIPT AUSGEFÜHRT WERDEN?" ${r} ${c} 3>&1 1>&2 2>&3)
          whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - OctoPi ${lng_wrd_configuration}" --title "${lng_wrd_octopi}" "HAST DU EINEN IOBROKER IN DEINEM NETZWERK UND SOLL DAS SKRIPT DEN BACKUPSTATUS AN DIESEN MELDEN?" ${r} ${c}
          yesno=$?
          if [ $yesno -eq 0 ]; then
            var_octoIOBroker=true
          fi
        fi
        ############### ERSTELLE BACKUPSKRIPT auf dem OctoPi
        ############### https://crontab.guru/#*_3_*_*_3
      else
        NEWT_COLORS='
          window=,red
          border=white,red
          textbox=white,red
          button=black,yellow
        ' \
        whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - OctoPi ${lng_wrd_configuration}" --title "${lng_wrd_octopi}" "${lng_txt_ip_unreachable} ${lng_ask_device_connected} ${lng_ask_ip_correct}" ${r} ${c}
        yesno=$?
        if [ $yesno -eq 0 ]; then
          var_octoip=""
          configOctopi
        fi
      fi
    fi
  fi
}

function startServerConfiguration() {
# Function configures Proxmox based on User Inputs, if this Script runs the First Time
  if [ -z $basicConfiguration ] || ! $basicConfiguration || $recoverConfig; then
  # Removes the enterprise repository and replaces it with the community repository
    {
      echo -e "XXX\n14\n${lng_wrd_configure} Proxmox ${lng_wrd_repository}\nXXX"
      if [ -f "/etc/apt/sources.list.d/pve-enterprise.list" ]; then
        rm /etc/apt/sources.list.d/pve-enterprise.list
    fi
      echo -e "XXX\n19\n${lng_wrd_configure} Proxmox ${lng_wrd_repository}\nXXX"
      if [ ! -f "/etc/apt/sources.list.d/pve-community.list" ]; then
        echo "deb http://download.proxmox.com/debian/pve $osname pve-no-subscription" >> /etc/apt/sources.list.d/pve-community.list 2>&1 >/dev/null
    fi
      echo -e "XXX\n26\n${lng_wrd_configure} Ceph ${lng_wrd_repository}\nXXX"
      if [ ! -f "/etc/apt/sources.list.d/ceph.list" ]; then
        echo "deb http://download.proxmox.com/debian/ceph-octopus $osname main" >> /etc/apt/sources.list.d/ceph.list 2>&1 >/dev/null
      fi

    # Performs a system update and installs software required for this script
      echo -e "XXX\n29\n${lng_txt_install_software}\nXXX"
      apt-get update 2>&1 >/dev/null
      for package in $pve_Standardsoftware; do
        if [ $(dpkg-query -W -f='${Status}' "$package" | grep -c "ok installed") -eq 0 ]; then
          apt-get install -y "$package" 2>&1 >/dev/null
        fi
      done
      echo -e "XXX\n56\n${lng_txt_install_updates}\nXXX"
      apt-get dist-upgrade -y 2>&1 >/dev/null && apt-get autoremove -y 2>&1 >/dev/null && pveam update 2>&1 >/dev/null

    # Aktiviere S.M.A.R.T. support auf Systemfestplatte
      echo -e "XXX\n92\n${lng_txt_config_smart} - ${lng_wrd_syshdd}\nXXX"
      if [ $(smartctl -a /dev/$rootDisk | grep -c "SMART support is: Enabled") -eq 0 ]; then
        smartctl -s on -a /dev/$rootDisk
      fi
    } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - Proxmox ${lng_wrd_configuration}" --title "${lng_wrd_basic} ${lng_wrd_configuration}" --gauge "${lng_wrd_preparation} ..." 6 ${c} 0
    basicConfiguration=true
  fi

  if [ -z $emailConfiguration ] || ! $emailConfiguration || $recoverConfig; then
  #Function configures the e-mail notification in Proxmox
    {
      if grep "root:" /etc/aliases; then
        sed -i "s/^root:.*$/root: $var_rootmail/" /etc/aliases
      else
        echo "root: $var_rootmail" >> /etc/aliases
      fi
      echo "root $var_senderaddress" >> /etc/postfix/canonical
      chmod 600 /etc/postfix/canonical
      echo [$var_mailserver]:"$var_mailport" "$var_mailusername":"$var_mailpassword" >> /etc/postfix/sasl_passwd
      chmod 600 /etc/postfix/sasl_passwd 
      sed -i "/#/!s/\(relayhost[[:space:]]*=[[:space:]]*\)\(.*\)/\1"[$var_mailserver]:"$var_mailport""/"  /etc/postfix/main.cf
      postconf smtp_use_tls=$var_mailtls
      if ! grep "smtp_sasl_password_maps" /etc/postfix/main.cf; then
        postconf smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd > /dev/null 2>&1
      fi
      if ! grep "smtp_tls_CAfile" /etc/postfix/main.cf; then
        postconf smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt > /dev/null 2>&1
      fi
      if ! grep "smtp_sasl_security_options" /etc/postfix/main.cf; then
        postconf smtp_sasl_security_options=noanonymous > /dev/null 2>&1
      fi
      if ! grep "smtp_sasl_auth_enable" /etc/postfix/main.cf; then
        postconf smtp_sasl_auth_enable=yes > /dev/null 2>&1
      fi 
      if ! grep "sender_canonical_maps" /etc/postfix/main.cf; then
        postconf sender_canonical_maps=hash:/etc/postfix/canonical > /dev/null 2>&1
      fi 
      postmap /etc/postfix/sasl_passwd > /dev/null 2>&1
      postmap /etc/postfix/canonical > /dev/null 2>&1
      systemctl restart postfix  &> /dev/null && systemctl enable postfix  &> /dev/null
      rm -rf "/etc/postfix/sasl_passwd"

      echo -e "XXX\n99\n${lng_wrd_preparation} ...\nXXX"
    } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - Proxmox ${lng_wrd_configuration}" --title "${lng_wrd_email} ${lng_wrd_configuration}" --gauge "${lng_wrd_preparation} ..." 6 ${c} 0

    # Test email settings
    echo -e "${lng_txt_testmail}\n\n${lng_txt_confirm_email}" | mail -s "[pve] ${lng_wrd_test} ${lng_wrd_message}" "$var_rootmail"
    whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - Proxmox ${lng_wrd_configuration}" --title "${lng_wrd_email} ${lng_wrd_configuration}" "${lng_txt_send_mail_to}\n\n$var_rootmail\n\n${lng_ask_successfully_delivered}" ${r} ${c}
    yesno=$?
    if [[ $yesno == 1 ]]; then
      NEWT_COLORS='
        window=,red
        border=white,red
        textbox=white,red
        button=black,yellow
      ' \
      whiptail --msgbox --ok-button " ${lng_btn_ok} " --backtitle "© 2021 - SmartHome-IoT.net - Proxmox ${lng_wrd_configuration}" --title "${lng_wrd_email} ${lng_wrd_configuration}" "${lng_txt_mail_error_check}" ${r} ${c}
      if grep "SMTPUTF8 is required" "/var/log/mail.log"; then
        if ! grep "smtputf8_enable = no" /etc/postfix/main.cf; then
          postconf smtputf8_enable=no
          postfix reload
        fi
      fi
      echo -e "${lng_txt_testmail}\n\n${lng_txt_confirm_email}" | mail -s "[pve] ${lng_wrd_test} ${lng_wrd_message}" "$var_rootmail"
      whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - Proxmox ${lng_wrd_configuration}" --title "${lng_wrd_email} ${lng_wrd_configuration}" "${lng_txt_send_mail_to}\n\n$var_rootmail\n\n${lng_ask_successfully_delivered}" ${r} ${c}
      yesno=$?
      if [[ $yesno == 1 ]]; then
        NEWT_COLORS='
          window=,red
          border=white,red
          textbox=white,red
          button=black,yellow
        ' \
        whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - Proxmox ${lng_wrd_configuration}" --title "${lng_wrd_email} ${lng_wrd_configuration}" "${lng_txt_mail_config_error}" ${r} ${c}
      fi
      sendmail=false
    else
      sendmail=true
    fi
    emailConfiguration=true
  fi

  if [ -z $sysHDDConfiguration ] || ! $sysHDDConfiguration || $recoverConfig; then
  # Set email notification about system hard disk errors, check every 12 hours
    sed -i 's+#enable_smart="/dev/hda /dev/hdb"+enable_smart="/dev/'"$rootDisk"'"+' /etc/default/smartmontools
    sed -i 's+#smartd_opts="--interval=1800"+smartd_opts="--interval=43200"+' /etc/default/smartmontools
    echo "start_smartd=yes" > /etc/default/smartmontools
    sed -i 's+DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner+#DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner+' /etc/smartd.conf
    sed -i 's+# /dev/sda -a -d sat+/dev/'"$rootDisk"' -a -d sat+' /etc/smartd.conf
    sed -i 's+#/dev/sda -d scsi -s L/../../3/18+/dev/'"$rootDisk"' -d sat -s L/../../1/02 -m root+' /etc/smartd.conf
    systemctl start smartmontools
    sysHDDConfiguration=true
  fi
  if [ -z $secHDDConfiguration ] || ! $secHDDConfiguration || $recoverConfig; then
  # Function configures the second hard disk if it is present and is an SSD
    {
      echo -e "XXX\n14\n${lng_txt_bind_sec_hdd}\nXXX"
      if [ $(pvesm status | grep -c data) -eq 0 ]; then
        if [ $(cat /sys/block/"$secondDisk"/queue/rotational) -eq 0 ]; then
          if [ $(pvesm status | grep 'data' | grep -c 'active') -eq 0 ]; then
            parted -s /dev/"$secondDisk" "mklabel gpt" > /dev/null 2>&1
            parted -s -a opt /dev/"$secondDisk" mkpart primary ext4 0% 100% > /dev/null 2>&1
            mkfs.ext4 -Fq -L data /dev/"$secondDisk"1 > /dev/null 2>&1
            mkdir -p /mnt/data > /dev/null 2>&1
            mount -o defaults /dev/"$secondDisk"1 /mnt/data > /dev/null 2>&1
            UUID=$(lsblk -o LABEL,UUID | grep 'data' | awk '{print $2}')
            echo "UUID=$UUID /mnt/data ext4 defaults 0 2" >> /etc/fstab
            pvesm add dir data --path /mnt/data
            pvesm set data --content iso,vztmpl,rootdir,images

            # Set email notification about hard disk errors, check every 12 hours
            sed -i 's+enable_smart="/dev/'"$rootDisk"'"+enable_smart="/dev/'"$rootDisk"' /dev/'"$secondDisk"'"+' /etc/default/smartmontools
            sed -i 's+/dev/'"$rootDisk"' -a -d sat+/dev/'"$rootDisk"' -a -d sat\n/dev/'"$secondDisk"' -a -d sat+' /etc/smartd.conf
            sed -i 's+#/dev/sdb -d scsi -s L/../../7/01+/dev/'"$secondDisk"' -d sat -s L/../../1/03 -m root+' /etc/smartd.conf
            systemctl restart smartmontools
          fi
        fi
      fi
      echo -e "XXX\n92\n${lng_txt_bind_sec_hdd}\nXXX"
    } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - Proxmox ${lng_wrd_configuration}" --title "${lng_wrd_basic} ${lng_wrd_configuration}" --gauge "${lng_wrd_preparation} ..." 6 ${c} 0
    secHDDConfiguration=true
  fi

  if [ -z $nasConfiguration ] || ! $nasConfiguration || $recoverConfig; then
  # Function mounts, if specified, the NAS as backup drive in Proxmox and makes it available to the containers as backup and media drive
    if [ -n "$var_nasip" ]; then
      pvesm add cifs backups --server "$var_nasip" --share "backups" --username "$var_robotname" --password "$var_robotpw" --content backup
      pvesh create /pools --poolid BackupPool --comment "${lng_txt_comment_backuppool}"
      echo "0 3 * * *   root   vzdump --compress zstd --mailto root --mailnotification always --exclude-path /mnt/ --exclude-path /media/ --mode snapshot --quiet 1 --pool BackupPool --maxfiles 6 --storage backups" >> /etc/cron.d/vzdump
    fi
    nasConfiguration=true
  fi

  if [ -z $firewallConfiguration ] || ! $firewallConfiguration || $recoverConfig; then
  # Function configures and activates the Proxmox firewall
    mkdir -p /etc/pve/firewall
    mkdir -p /etc/pve/nodes/$hostname
    # Cluster level firewall
    echo -e "[OPTIONS]\nenable: 1\n\n[IPSET network] # ${lng_wrd_homenetwork}\n$networkIP.0/$cidr\n\n[IPSET pnetwork] # ${lng_txt_privatenetworks_comment}\n10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16\n\n[RULES]\nGROUP proxmox\n\n[group proxmox]\nIN SSH(ACCEPT) -source +network -log nolog\nIN ACCEPT -source +network -p tcp -dport 8006 -log nolog\n\n" > $clusterfileFW
    # Host level Firewall
    echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP proxmox\n\n" > $hostfileFW
    firewallConfiguration=true
  fi
}

function createConfigFile() {
# Function creates the config File, if you run this Script again or use it after Proxmox reinstallation
  if [ -n "$var_nasip" ] && [ -f /mnt/pve/backups/Proxmox_Configuration.txt ]; then rm /mnt/pve/backups/Proxmox_Configuration.txt; fi
  if [ -f "${configFile}" ]; then rm $configFile; fi
  echo -e "\0043\0041/bin/bash" > $configFile
  echo -e "\n\0043\0043 NOTICE: Backup Proxmox Configuration Script from SmartHome-IoT.net \0043\0043" >> $configFile
  echo -e "\0043\0043         Variables starting with var_ were created by you           \0043\0043" >> $configFile
  echo -e "\n\0043 Proxmox-/System configuration" >> $configFile
  echo -e "basicConfiguration=$basicConfiguration" >> $configFile
  echo -e "pveIP=$pveIP" >> $configFile
  echo -e "fqdn=$fqdn" >> $configFile
  echo -e "hostname=$hostname" >> $configFile
  echo -e "osname=$osname" >> $configFile
  echo -e "timezone=$timezone" >> $configFile
  echo -e "\nvar_language=$var_language" >> $configFile
  echo -e "\n\0043 Gateway configuration" >> $configFile
  echo -e "var_gwmanufacturer=$var_gwmanufacturer" >> $configFile
  echo -e "gatewayIP=$gatewayIP" >> $configFile
  echo -e "networkIP=$networkIP" >> $configFile
  echo -e "cidr=$cidr" >> $configFile
  echo -e "var_servervlan=$var_servervlan" >> $configFile
  echo -e "var_smarthomevlan=$var_smarthomevlan" >> $configFile
  echo -e "var_guestvlan=$var_guestvlan" >> $configFile
  echo -e "\n\0043 Firewall configuration" >> $configFile
  echo -e "firewallConfiguration=$firewallConfiguration" >> $configFile
  echo -e "clusterfileFW=$clusterfileFW" >> $configFile
  echo -e "hostfileFW=$hostfileFW" >> $configFile
  echo -e "\n\0043 SMTP-Server configuration" >> $configFile
  echo -e "emailConfiguration=$emailConfiguration" >> $configFile
  echo -e "var_rootmail=$var_rootmail" >> $configFile
  echo -e "var_mailserver=$var_mailserver" >> $configFile
  echo -e "var_mailport=$var_mailport" >> $configFile
  echo -e "var_mailusername=$var_mailusername" >> $configFile
  echo -e "var_mailpassword=\"\"" >> $configFile
  echo -e "var_senderaddress=$var_senderaddress" >> $configFile
  echo -e "var_mailtls=$var_mailtls" >> $configFile
  echo -e "sendmail=$sendmail" >> $configFile
  echo -e "\n\0043 HDD-/Storage configuration" >> $configFile
  echo -e "sysHDDConfiguration=$sysHDDConfiguration      \0043 DO NOT CHANGE THIS!!!" >> $configFile
  echo -e "rootDisk=$rootDisk" >> $configFile
  echo -e "secHDDConfiguration=$secHDDConfiguration" >> $configFile
  echo -e "secondDisk=$secondDisk" >> $configFile
  echo -e "ctTemplateDisk=$ctTemplateDisk" >> $configFile
  echo -e "\n\0043 Netrobot configuration" >> $configFile
  echo -e "var_robotname=$var_robotname" >> $configFile
  echo -e "var_robotpw=\"\"" >> $configFile
  echo -e "\n\0043 NAS configuration" >> $configFile
  echo -e "nasConfiguration=$nasConfiguration" >> $configFile
  echo -e "var_nasip=$var_nasip" >> $configFile
  echo -e "var_synologynas=$var_synologynas" >> $configFile
  echo -e "\n\0043 OctoPi configuration" >> $configFile
  echo -e "var_octoip=$var_octoip" >> $configFile
  sed -i 's/ //g' $configFile
  if [ -n "$var_nasip" ]; then cp $configFile /mnt/pve/backups/Proxmox_Configuration.txt; fi
}

####################### start Script ######################
clear
chooseLanguage

if [[ $1 == "nas" ]]; then
  source $configFile
  if [ -z "$var_robotpw" ]; then
    var_robotpw=$(whiptail --passwordbox --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_cancel} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_password}" "\n${lng_txt_netrobot_password}\n\n${lng_ask_netrobot_password}" ${ri} ${c} 3>&1 1>&2 2>&3)
  fi
  mountNASAfterConfig
fi

checkConfigFile

if $recoverConfig; then
  source $configFile
  if [ -z "$var_robotpw" ]; then
    var_robotpw=$(whiptail --passwordbox --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_cancel} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_password}" "\n${lng_txt_netrobot_password}\n\n${lng_ask_netrobot_password}" ${ri} ${c} 3>&1 1>&2 2>&3)
  fi
  if [ -z "$var_mailpassword" ]; then
    var_mailpassword=$(whiptail --passwordbox --ok-button " ${lng_btn_ok} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_mailconfiguration}" --title "${lng_wrd_mailserver}" "\n${lng_ask_mail_server_password}" ${ri} ${c} 3>&1 1>&2 2>&3)
  fi
  startServerConfiguration
else
  informUser
  configNetrobot
  configGateway
  configSMTPServer
  configNAS
  configOctopi
  startServerConfiguration
fi

createConfigFile

whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_txt_recover_config}" --title "${lng_wrd_config_file}" "\n${lng_txt_config_done}\n\n${lng_ask_add_lxc}" ${r} ${c}
yesno=$?
if [ $yesno -eq 0 ]; then
  curl -sSL https://lxc.config.shiot.de | bash
  exit
fi

exit
