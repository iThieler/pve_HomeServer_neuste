#!/bin/bash

osAlpine3_11="alpine-3.11-default"   # Container Template for Alpine v3.11
osAlpine3_12="alpine-3.12-default"   # Container Template for Alpine v3.12
osArchlinux="archlinux-base"   # Container Template for archLinux
osCentos7="centos-7-default"   # Container Template for Centos v7
osCentos8="centos-8-default"   # Container Template for Centos v8
osDebian9="debian-9.0-standard"   # Container Template for Debian v9
osDebian10="debian-10-standard"   # Container Template for Debian v10
osDevuan3_0="devuan-3.0-standard"   # Container Template for Devuan v3.0
osFedora32="fedora-32-default"   # Container Template for Fedora v32
osFedora33="fedora-33-default"   # Container Template for Fedora v33
osGentoo="gentoo-current-default"   # Container Template for current Gentoo
osOpensuse15_2="opensuse-15.2-default"   # Container Template for openSUSE v15.2
osUbuntu18_04="ubuntu-18.04-standard"   # Container Template for Ubuntu v18.04
osUbuntu20_04="ubuntu-20.04-standard"   # Container Template for Ubuntu v20.04
osUbuntu20_10="ubuntu-20.10-standard"   # Container Template for Ubuntu v20.10

pve_Standardsoftware="parted smartmontools libsasl2-modules lxc-pve"  # Software that is installed afterwards on the server host
lxc_Standardsoftware="curl wget software-properties-common apt-transport-https lsb-release gnupg2 net-tools"  #Software that is installed first on each LXC

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
containerURL="https://raw.githubusercontent.com/shiot/HomeServer_container/master"

# Container Variables
ctIDall=$(pct list | tail -n +2 | awk '{print $1}')

# check if Script runs FirstTime
configFile="/root/.cfg_shiot"

##################### Selection menus #####################

# Language selctor
lng=(\
  "de" "      Deutsch                                                " \
  "en" "      English" \
)

# Gateway selector
gw=(\
  "unifi" "   Ubiquiti/UniFi DreamMachine Pro ${lng_or} CloudKey     " off \
  "avm" "     AVM FRITZ!Box" off \
  "andere" "  ${lng_another_manufacturer}" off \
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
  if [ -z $1 ]; then
    pct exec $1 -- bash -ci "cat /dev/null > ~/.bash_history && history -c && history -w"
  else
    cat /dev/null > ~/.bash_history && history -c && history -w
  fi
}

function pingDevice() {
# Function checks if the given IP-Adress is reachable
  {
    sleep 0.5
    ping -c 1 $1
    rc=$?
    if [[ $rc -eq 0 ]]; then
      echo 99
      sleep 2
      echo 100
      return 0
    else
      echo 99
      sleep 2
      echo 100
    fi
  } | whiptail --gauge "DAS GERÄT WIRD IM NETZWERK GESUCHT..." 10 80 0
  return 1
}

function checkConfigFile() {
# Function Check if this script run the first time
  if [ -f "${configFile}" ]; then
    clear
    echo -e "\n\nDIE ERSTKONFIGURATION VON PROXMOX, WURDE DURCH DIESES SKRIPT SCHON AUSGEFÜHRT. WENN DU DIESES SKRIPT ERNEUT AUSFÜHRST, KANN DEIN SYSTEM INSTABIL WERDEN. BITTE INSTALLIERE PROXMOX NEU UND FÜHRE ANSCHLIEßEND DIESES SKRIPT ERNEUT AUS. DEINE CONTAINER KANNST DU ANSCHLIEßEND AUS VORHANDENEN BACKUPS WIEDERHERSTELLEN."
    exit
  else
    whiptail --yesno --yes-button " JA " --no-button " NEIN " --backtitle "© 2021 - SmartHome-IoT.net - KONFIGURATION WIEDERHERSTELLEN" --title "SPEICHERORT" "HAST DU DIESES KONFIGURATIONSSKRIPT SCHONMAL BEI EINER ANDEREN PROXMOX KONFIGURATION VERWENDET UND MÖCHTEST DIE SELBE KONFIGURATION ERNEUT NUTZEN?" ${r} ${c}
    yesno=$?
    if [ $yesno -eq 0 ]; then
      mkdir /mnt/cfg_temp
      cfg_mountPath=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - KONFIGURATION WIEDERHERSTELLEN" --title "SPEICHERORT - FREIGABEPFAD" "BITTE GIB DEN FREIGABEPFAD AN" ${ri} ${c} //IP-ADRESSE/PFAD 3>&1 1>&2 2>&3)
      cfg_Filename=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - KONFIGURATION WIEDERHERSTELLEN" --title "SPEICHERORT - DATEINAME" "BITTE GIB DEN DATEINAMEN AN" ${ri} ${c} .cfg_shiot 3>&1 1>&2 2>&3)
      cfg_mountUser=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - KONFIGURATION WIEDERHERSTELLEN" --title "SPEICHERORT - BENUTZERNAME" "BITTE GIB DEN BENUTZERNAMEN AN" ${ri} ${c} BENUTZERNAME 3>&1 1>&2 2>&3)
      cfg_mountPass=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - KONFIGURATION WIEDERHERSTELLEN" --title "SPEICHERORT - PASSWORT" "BITTE GIB DASPASSWORT AN" ${ri} ${c} PASSWORT 3>&1 1>&2 2>&3)
      cfg_Summary="
        FREIGABEPFAD: $cfg_mountPath
        DATEINAME: $cfg_Filename
        BENUTZERNAME: $cfg_mountUser
        PASSWORT: $cfg_mountPass
        "
      whiptail --yesno --yes-button " JA " --no-button " NEIN " --backtitle "© 2021 - SmartHome-IoT.net - KONFIGURATION WIEDERHERSTELLEN" --title "ZUSAMMENFASSUNG" "DU HAST FOLGENDE DATEN ANGEGEBEN\n$cfg_Summary\nSIND DIE DATEN KORREKT?" ${r} ${c}
      yesno=$?
      if [ $yesno -eq 0 ]; then
        mount -t cifs -o user="$cfg_mountUser",password="$cfg_mountPass",rw,file_mode=0777,dir_mode=0777 $cfg_mountPath /mnt/cfg_temp
        cp /mnt/cfg_temp/$cfg_Filename $configFile
        umount /mnt/cfg_temp
        rm -d /mnt/cfg_temp
        return 0
      else
        NEWT_COLORS='
          window=,red
          border=white,red
          textbox=white,red
          button=black,white
        ' \
        whiptail --yesno --yes-button " ERNEUT AUFRUFEN " --nocancel --no-button " BEENDEN " --backtitle "© 2021 - SmartHome-IoT.net - FEHLER" --title "FEHLER" "ES WERDEN KEINE ÄNDERUNGEN AN DEINEM PROXMOXSERVER VORGENOMMEN. WENN DU DIE KONFIGURATION DOCH DURCH DIESES SKRIPT DURCHFÜHREN MÖCHTEST,MUSST DU ES ERNEUT AUFRUFEN." ${r} ${c}
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
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_welcome" "$lng_start_info" ${r} ${c}
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_introduction" "$lng_introduction_text" ${r} ${c}
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_netrobot" "$lng_netrobot_text" ${r} ${c}
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_secure_password" "$lng_secure_password_text $networkrobotpw $lng_secure_password_text1" ${r} ${c}
}

function configNetrobot() {
# Function ask User for Netrobot Configuration
  if [ -z "$var_robotname" ]; then
    var_robotname=$(whiptail --inputbox --ok-button " $lng_ok " --cancel-button " $lng_cancel " --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_netrobot_name" "$lng_netrobot_name_text" ${r} ${c} netrobot 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 1 ]; then
      NEWT_COLORS='
        window=,red
        border=white,red
        textbox=white,red
        button=black,white
      ' \
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_abort" --title "$lng_abort" "$lng_abort_text" ${r} ${c}
      exit 1
    fi
  fi
  var_robotpw=$(whiptail --passwordbox --ok-button " $lng_ok " --cancel-button " $lng_cancel " --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_netrobot_password" "$lng_netrobot_password_text\n\n$lng_netrobot_password_text1" ${r} ${c} 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 1 ]; then
    NEWT_COLORS='
      window=,red
      border=white,red
      textbox=white,red
      button=black,white
    ' \
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_abort" --title "$lng_abort" "$lng_abort_text" ${r} ${c}
    exit 1
  fi
  if [[ $var_robotpw = "" ]]; then
    var_robotpw=$(createPassword 26)
  fi
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_netrobot_password" "BITTE ERSTELLE EINEN BENUTZER MIT FOLGENDEN DATEN\n\nBENUTZERNAME: $var_robotname\nPASSWORT: $var_robotpw\n\nUND ERTEILE DEM BENUTZER ADMINRECHTE" ${r} ${c}
}

function configGateway() {
# Function ask User for Gateway Manufacturer
  if [ -z "$var_gwmanufacturer" ]; then
    var_gwmanufacturer=$(whiptail --radiolist --ok-button " $lng_ok " --cancel-button " $lng_cancel " --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_gateway_manufacturer" "$lng_gateway_manufacturer" ${r} ${c} 10 "${gw[@]}" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 1 ]; then
      NEWT_COLORS='
        window=,red
        border=white,red
        textbox=white,red
        button=black,white
      ' \
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_abort" --title "$lng_abort" "$lng_abort_text" ${r} ${c}
      exit 1
    fi
    if [[ $var_gwmanufacturer == "andere" ]]; then
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_gateway_manufacturer" "$lng_another_manufacturer_text" ${r} ${c}
    fi
    if [[ $var_gwmanufacturer == "unifi" ]]; then
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_info" ${r} ${c}
      whiptail --yesno --yes-button " $lng_yes " --no-button " $lng_no " --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_ask" ${r} ${c}
      yesno=$?
      if [ $yesno -eq 0 ]; then
        var_servervlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_text_server" ${r} ${c} 100 3>&1 1>&2 2>&3)
        var_smarthomevlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_text_smarthome" ${r} ${c} 200 3>&1 1>&2 2>&3)
        var_guestvlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_text_guest" ${r} ${c} 300 3>&1 1>&2 2>&3)
      fi
    fi
  fi
}

function configSMTPServer() {
# Function ask User for SMTP-Server-Configuration
  if [ -z "$var_rootmail" ]; then
    var_rootmail=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_root" "$lng_mail_root_text" ${r} ${c} 3>&1 1>&2 2>&3)
  fi
  if [ -z "$var_mailserver" ]; then
    var_mailserver=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server" "$lng_mail_server_text" ${r} ${c} 3>&1 1>&2 2>&3)
  fi
  if [ -z "$var_mailport" ]; then
    var_mailport=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server_port" "$lng_mail_server_port_text" ${r} ${c} 587 3>&1 1>&2 2>&3)
  fi
  if [ -z "$var_mailusername" ]; then
    var_mailusername=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server_user" "$lng_mail_server_user_text" ${r} ${c} 3>&1 1>&2 2>&3)
  fi
  if [ -z "$var_mailpassword" ]; then
    var_mailpassword=$(whiptail --passwordbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server_user_password" "$lng_mail_server_user_password_text \"$var_mailusername\"" ${r} ${c} 3>&1 1>&2 2>&3)
  fi
  if [ -z "$var_senderaddress" ]; then
    var_senderaddress=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_sender" "$lng_mail_sender_text" ${r} ${c} "notify@$(echo "$var_rootmail" | cut -d\@ -f2)" 3>&1 1>&2 2>&3)
  fi
  if [ -z "$var_mailtls" ]; then
    whiptail --yesno --yes-button " $lng_yes " --no-button " $lng_no " --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_tls" "$lng_mail_tls_text" ${r} ${c}
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
    whiptail --yesno --yes-button " $lng_yes " --no-button " $lng_no " --backtitle "© 2021 - SmartHome-IoT.net - SPEICHER- UND NAS KONFIGURATION" --title "SPEICHER- UND NAS KONFIGURATION" "BEFINDET SICH EINE NAS '(QNAP, SYNOLOGY, USW.)' IN DEINEM NETZWERK?" ${r} ${c}
    yesno=$?
    if [ $yesno -eq 0 ]; then
      var_iptocheck=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - SPEICHER- UND NAS KONFIGURATION" --title "IP-ADRESSE" "WIE LAUTET DIE IP-ADRESSE UNTER DER DEINE NAS ERREICHBAR IST?" ${r} ${c} 3>&1 1>&2 2>&3)
      if pingDevice $var_iptocheck; then
        var_nasip=$var_iptocheck
      else
        NEWT_COLORS='
          window=,red
          border=white,red
          textbox=white,red
          button=black,white
        ' \
        whiptail --yesno --yes-button " $lng_yes " --no-button " $lng_no " --backtitle "© 2021 - SmartHome-IoT.net - SPEICHER- UND NAS KONFIGURATION" --title "IP-ADRESSE" "DIE ANGEGEBENE IP-ADRESSE IST NICHT ERREICHBAR. IST DAS GERÄT EINGESCHALTET UND MIT DEM NETZWERK VERBUNDEN? IST DIE IP-ADRESSE KORREKT?" ${r} ${c}
        yesno=$?
        if [ $yesno -eq 0 ]; then
          var_nasip=""
          configNAS
        fi
      fi
      whiptail --yesno --yes-button " JA " --no-button " NEIN " --backtitle "© 2021 - SmartHome-IoT.net - SPEICHER- UND NAS KONFIGURATION" --title "NAS HERSTELLER" "HANDELT ES SICH BEI DEINER NAS UM EINE SYNOLOGY DISKSTATION?" ${r} ${c}
      yesno=$?
      if [[ $yesno == 1 ]]; then
        var_synologynas=true
      else
        var_synologynas=false
      fi
      whiptail --yesno --yes-button " JA " --no-button " NEIN " --backtitle "© 2021 - SmartHome-IoT.net - SPEICHER- UND NAS KONFIGURATION" --title "FREIGEGEBENE ORDNER" "IN DIESEM SKRIPT WERDEN AUF DER NAS ZWEI FREIGEGEBENE ORDNER BENÖTIGT. ERSTELLE DIE ORDNER\n\nbackups\nmedia\n\nUND WEISE DEM NETZWERKROBOTER \"$var_robotname\" LESE-/SCHREIBRECHTE ZU.\n\nFERTIG?" ${r} ${c}
      yesno=$?
      if [[ $yesno == 1 ]]; then
        NEWT_COLORS='
          window=,red
          border=white,red
          textbox=white,red
          button=black,white
        ' \
        whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - SPEICHER- UND NAS KONFIGURATION" --title "FREIGEGEBENE ORDNER" "WENN DIESE ORDNER NICHT EXISTIEREN, ODER DEIN NETZWERKROBOTER KEINE LESE-/SCHREIBRECHTE BESITZT, KANN DIESES SKRIPT DEINE NAS NICHT ORDENTLICH EINBINDEN.\n\nES WIRD OHNE NASEINBINDUNG FORTGEFAHREN." ${r} ${c}
      fi
    fi
  fi
}

function configOctopi() {
# Function asks user if there is a 3D printer on the network and he wants to create a backup script for OctoPi
  if [ -z $var_octoip ]; then
    whiptail --yesno --yes-button " $lng_yes " --no-button " $lng_no " --backtitle "© 2021 - SmartHome-IoT.net - OctoPi KONFIGURATION" --title "OctoPi KONFIGURATION" "BEFINDET SICH EIN 3D-DRUCKER DERVON EINEM OCTOPI GESTEUERT WIRD IN DEINEM NETZWERK?" ${r} ${c}
    yesno=$?
    if [ $yesno -eq 0 ]; then
      var_iptocheck=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - OctoPi KONFIGURATION" --title "IP-ADRESSE" "WIE LAUTET DIE IP-ADRESSE UNTER DER DEIN OCTOPI ERREICHBAR IST?" ${r} ${c} 3>&1 1>&2 2>&3)
      if pingDevice $var_iptocheck; then
        var_octoip=$var_iptocheck
      else
        NEWT_COLORS='
          window=,red
          border=white,red
          textbox=white,red
          button=black,white
        ' \
        whiptail --yesno --yes-button " $lng_yes " --no-button " $lng_no " --backtitle "© 2021 - SmartHome-IoT.net - OctoPi KONFIGURATION" --title "IP-ADRESSE" "DIE ANGEGEBENE IP-ADRESSE IST NICHT ERREICHBAR. IST DAS GERÄT EINGESCHALTET UND MIT DEM NETZWERK VERBUNDEN? IST DIE IP-ADRESSE KORREKT?" ${r} ${c}
        yesno=$?
        if [ $yesno -eq 0 ]; then
          var_octoip=""
          configOctopi
        fi
      fi
      whiptail --yesno --yes-button " $lng_yes " --no-button " $lng_no " --backtitle "© 2021 - SmartHome-IoT.net - OctoPi KONFIGURATION" --title "BACKUPSCRIPT" "SOLL EIN BACKUPSKRIPT ERSTELLT WERDEN, WELCHES DU AUF DEINEN OCTOPI LADEN KANNST? BACKUPS WERDEN IM BACKUPVERZEICHNIS DEINER NAS ERSTELLT." ${r} ${c}
      yesno=$?
      if [ $yesno -eq 0 ]; then
        var_octoUser=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - OctoPi KONFIGURATION" --title "BACKUPSCRIPT" "WIE LAUTET DER BENUTZERNAME UNTER DEM DER OCTOPI-DIENST AUSGEFÜHRT WIRD?" ${r} ${c} 3>&1 1>&2 2>&3)
        var_octoCron=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - OctoPi KONFIGURATION" --title "BACKUPSCRIPT" "ZU WELCHEM ZEITPUNKT SOLL DASBACKUPSKRIPT AUSGEFÜHRT WERDEN?" ${r} ${c} 3>&1 1>&2 2>&3)
        whiptail --yesno --yes-button " $lng_yes " --no-button " $lng_no " --backtitle "© 2021 - SmartHome-IoT.net - OctoPi KONFIGURATION" --title "BACKUPSCRIPT" "HAST DU EINEN IOBROKER IN DEINEM NETZWERK UND SOLL DAS SKRIPT DEN BACKUPSTATUS AN DIESEN MELDEN?" ${r} ${c}
        yesno=$?
        if [ $yesno -eq 0 ]; then
          var_octoIOBroker=true
        fi
      fi
      ############### ERSTELLE BACKUPSKRIPT auf dem OctoPi
    fi
  fi
}

function startServerConfiguration() {
# Function configures Proxmox based on User Inputs, if this Script runs the First Time
  if [ -z $basicConfiguration ] || ! $basicConfiguration; then
  # Removes the enterprise repository and replaces it with the community repository
    {
      echo -e "XXX\n14\n$lng_pve_configuration_enterprise\nXXX"
      if [ -f "/etc/apt/sources.list.d/pve-enterprise.list" ]; then
        rm /etc/apt/sources.list.d/pve-enterprise.list
    fi
      echo -e "XXX\n19\n$lng_pve_configuration_community\nXXX"
      if [ ! -f "/etc/apt/sources.list.d/pve-community.list" ]; then
        echo "deb http://download.proxmox.com/debian/pve $osname pve-no-subscription" >> /etc/apt/sources.list.d/pve-community.list 2>&1 >/dev/null
    fi
      echo -e "XXX\n26\n$lng_pve_configuration_ceph\nXXX"
      if [ ! -f "/etc/apt/sources.list.d/ceph.list" ]; then
        echo "deb http://download.proxmox.com/debian/ceph-octopus $osname main" >> /etc/apt/sources.list.d/ceph.list 2>&1 >/dev/null
      fi

    # Performs a system update and installs software required for this script
      echo -e "XXX\n29\n$lng_pve_configuration_install\nXXX"
      apt-get update 2>&1 >/dev/null
      for package in $pve_Standardsoftware; do
        if [ $(dpkg-query -W -f='${Status}' "$package" | grep -c "ok installed") -eq 0 ]; then
          apt-get install -y "$package" 2>&1 >/dev/null
        fi
      done
      echo -e "XXX\n56\n$lng_pve_configuration_update\nXXX"
      apt-get dist-upgrade -y 2>&1 >/dev/null && apt-get autoremove -y 2>&1 >/dev/null && pveam update 2>&1 >/dev/null

    # Aktiviere S.M.A.R.T. support auf Systemfestplatte
      echo -e "XXX\n92\n$lng_pve_configuration_smart\nXXX"
      if [ $(smartctl -a /dev/$rootDisk | grep -c "SMART support is: Enabled") -eq 0 ]; then
        smartctl -s on -a /dev/$rootDisk
      fi
    } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_pve_configuration" --title "$lng_pve_configuration" --gauge "$lng_preparation" 6 ${c} 0
    basicConfiguration=true
  fi

  if [ -z $emailConfiguration ] || ! $emailConfiguration; then
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

      echo -e "XXX\n99\n$lng_preparation\nXXX"
    } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_configuration" --gauge "$lng_preparation" 6 ${c} 0

    # Test email settings
    echo -e "$lng_mail_configuration_test_message" | mail -s "[pve] $lng_mail_configuration_test_message_subject" "$var_rootmail"
    whiptail --yesno --yes-button " $lng_yes " --no-button " $lng_no " --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_configuration_test" "$lng_mail_configuration_test_text\n\n$var_rootmail\n\nWurde die E-Mail erfolgreich zugestellt (Es kann je nach Anbieter bis zu 15 Minuten dauern)?" ${r} ${c}
    yesno=$?
    if [[ $yesno == 1 ]]; then
      NEWT_COLORS='
        window=,red
        border=white,red
        textbox=white,red
        button=black,white
      ' \
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_error" "$lng_error_text" ${r} ${c}
      if grep "SMTPUTF8 is required" "/var/log/mail.log"; then
        if ! grep "smtputf8_enable = no" /etc/postfix/main.cf; then
          postconf smtputf8_enable=no
          postfix reload
        fi
      fi
      echo -e "$lng_mail_configuration_test_message" | mail -s "[pve] $lng_mail_configuration_test_message_subject" "$var_rootmail"
      whiptail --yesno --yes-button " $lng_yes " --no-button " $lng_no " --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_configuration_test" "$lng_mail_configuration_test_text\n\n$var_rootmail\n\nWurde die E-Mail erfolgreich zugestellt (Es kann je nach Anbieter bis zu 15 Minuten dauern)?" ${r} ${c}
      yesno=$?
      if [[ $yesno == 1 ]]; then
        NEWT_COLORS='
          window=,red
          border=white,red
          textbox=white,red
          button=black,white
        ' \
        whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_error" "$lng_error_text1" ${r} ${c}
      fi
    fi
    emailConfiguration=true
  fi

  if [ -z $sysHDDConfiguration ] || ! $sysHDDConfiguration; then
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
  if [ -z $secHDDConfiguration ] || ! $secHDDConfiguration; then
  # Function configures the second hard disk if it is present and is an SSD
    {
      echo -e "XXX\n14\n$lng_nas_configuration_hdd\nXXX"
      countDisks=$(echo "$otherDisks" | wc -l)
      if [ "$countDisks" -eq 1 ]; then
        if [ $(pvesm status | grep -c data) -eq 0 ]; then
          if [ $(cat /sys/block/"$otherDisks"/queue/rotational) -eq 0 ]; then
            if [ $(pvesm status | grep 'data' | grep -c 'active') -eq 0 ]; then
              parted -s /dev/"$otherDisks" "mklabel gpt" > /dev/null 2>&1
              parted -s -a opt /dev/"$otherDisks" mkpart primary ext4 0% 100% > /dev/null 2>&1
              mkfs.ext4 -Fq -L data /dev/"$otherDisks"1 > /dev/null 2>&1
              mkdir -p /mnt/data > /dev/null 2>&1
              mount -o defaults /dev/"$otherDisks"1 /mnt/data > /dev/null 2>&1
              UUID=$(lsblk -o LABEL,UUID | grep 'data' | awk '{print $2}')
              echo "UUID=$UUID /mnt/data ext4 defaults 0 2" >> /etc/fstab
              pvesm add dir data --path /mnt/data
              pvesm set data --content iso,vztmpl,rootdir,images

              # Set email notification about hard disk errors, check every 12 hours
              sed -i 's+enable_smart="/dev/'"$rootDisk"'"+enable_smart="/dev/'"$rootDisk"' /dev/'"$otherDisks"'"+' /etc/default/smartmontools
              sed -i 's+/dev/'"$rootDisk"' -a -d sat+/dev/'"$rootDisk"' -a -d sat\n/dev/'"$otherDisks"' -a -d sat+' /etc/smartd.conf
              sed -i 's+#/dev/sdb -d scsi -s L/../../7/01+/dev/'"$otherDisks"' -d sat -s L/../../1/03 -m root+' /etc/smartd.conf
              systemctl restart smartmontools
            fi
          fi
        fi
      fi
      echo -e "XXX\n92\n$lng_nas_configuration_hdd\nXXX"
    } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_configuration" --gauge "$lng_preparation" 6 ${c} 0
    secHDDConfiguration=true
  fi

  if [ -z $nasConfiguration ] || ! $nasConfiguration; then
  # Function mounts, if specified, the NAS as backup drive in Proxmox and makes it available to the containers as backup and media drive
    if [ -n "$var_nasip" ]; then
      pvesm add cifs backups --server "$var_nasip" --share "backups" --username "$var_robotname" --password "$var_robotpw" --content backup
      pvesh create /pools --poolid BackupPool --comment "$lng_lxcpool_comment"
      echo "0 3 * * *   root   vzdump --compress zstd --mailto root --mailnotification always --exclude-path /mnt/ --exclude-path /media/ --mode snapshot --quiet 1 --pool BackupPool --maxfiles 6 --storage backups" >> /etc/cron.d/vzdump
    fi
    nasConfiguration=true
  fi

  if [ -z $firewallConfiguration ] || ! $firewallConfiguration; then
  # Function configures and activates the Proxmox firewall
    mkdir -p /etc/pve/firewall
    mkdir -p /etc/pve/nodes/$hostname
    # Cluster level firewall
    echo -e "[OPTIONS]\nenable: 1\n\n[IPSET network] # $lng_homenetwork\n$networkIP.0/$cidr\n\n[IPSET pnetwork] # $lng_privatenetworks\n10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16\n\n[RULES]\nGROUP proxmox\n\n[group proxmox]\nIN SSH(ACCEPT) -source +network -log nolog\nIN ACCEPT -source +network -p tcp -dport 8006 -log nolog\n\n" > $clusterfileFW
    # Host level Firewall
    echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP proxmox\n\n" > $hostfileFW
    firewallConfiguration=true
  fi
}

function createConfigFile() {
# Function creates the config File, if you run this Script again or use it after Proxmox reinstallation
  if [ -n "$var_nasip" ]; then rm /mnt/pve/backups/.cfg_shiot; fi
  rm $configFile
  echo -e "\0043\0041/bin/bash" > $configFile
  echo -e "\0043\0043 NOTICE: Backup Proxmox Configuration Script from SmartHome-IoT.net \0043\0043" >> $configFile
  echo -e "\0043\0043         Variables starting with var_ were created by you           \0043\0043" >> $configFile
  echo -e "\n\0043 Proxmox-/System configuration" >> $configFile
  echo "basicConfiguration=$basicConfiguration" >> $configFile
  echo "pveIP=$pveIP" >> $configFile
  echo "fqdn=$fqdn" >> $configFile
  echo "hostname=$hostname" >> $configFile
  echo "osname=$osname" >> $configFile
  echo "timezone=$timezone" >> $configFile
  echo -e "\n\0043 Gateway configuration" >> $configFile
  echo "var_gwmanufacturer=$var_gwmanufacturer" >> $configFile
  echo "gatewayIP=$gatewayIP" >> $configFile
  echo "networkIP=$networkIP" >> $configFile
  echo "cidr=$cidr" >> $configFile
  echo "var_servervlan=$var_servervlan" >> $configFile
  echo "var_smarthomevlan=$var_smarthomevlan" >> $configFile
  echo "var_guestvlan=$var_guestvlan" >> $configFile
  echo -e "\n\0043 Firewall configuration" >> $configFile
  echo "firewallConfiguration=$firewallConfiguration" >> $configFile
  echo "clusterfileFW=$clusterfileFW" >> $configFile
  echo "hostfileFW=$hostfileFW" >> $configFile
  echo -e "\n\0043 SMTP-Server configuration" >> $configFile
  echo "emailConfiguration=$emailConfiguration" >> $configFile
  echo "var_rootmail=$var_rootmail" >> $configFile
  echo "var_mailservervar_mailserver" >> $configFile
  echo "var_mailport=$var_mailport" >> $configFile
  echo "var_mailusername=$var_mailusername" >> $configFile
  echo "var_mailpassword=\"\"" >> $configFile
  echo "var_senderaddress=$var_senderaddress" >> $configFile
  echo "var_mailtls=$var_mailtls" >> $configFile
  echo -e "\n\0043 HDD-/Storage configuration" >> $configFile
  echo "sysHDDConfiguration=$sysHDDConfiguration      \0043 DO NOT CHANGE THIS!!!" >> $configFile
  echo "rootDisk=$rootDisk" >> $configFile
  echo "secHDDConfiguration=$secHDDConfiguration" >> $configFile
  echo "secondDisk=$secondDisk" >> $configFile
  echo "ctTemplateDisk=$ctTemplateDisk" >> $configFile
  echo -e "\n\0043 Netrobot configuration" >> $configFile
  echo "var_robotname=$var_robotname" >> $configFile
  echo "var_robotpw=\"\"" >> $configFile
  echo -e "\n\0043 NAS configuration" >> $configFile
  echo "nasConfiguration=$nasConfiguration" >> $configFile
  echo "var_nasip=$var_nasip" >> $configFile
  echo "var_synologynas=$var_synologynas" >> $configFile
  echo -e "\n\0043 OctoPi configuration" >> $configFile
  echo "var_octoip=$var_octoip" >> $configFile
  if [ -n "$var_nasip" ]; then cp $configFile /mnt/pve/backups/Proxmox_Configuration; fi
}

####################### start Script ######################
chooseLanguage
if checkConfigFile; then source $configFile; fi

informUser
configNetrobot
configGateway
configSMTPServer
configNAS
startServerConfiguration
createConfigFile
exit
