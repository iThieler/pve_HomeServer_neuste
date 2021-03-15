#!/bin/bash

osAlpine="alpine-3.12-default"   # Container Template for Alpine v3.12
osArchlinux="archlinux-base"   # Container Template for archLinux
osCentos="centos-8-default"   # Container Template for Centos v8
osDebian="debian-10-standard"   # Container Template for Debian v10
osDevuan="devuan-3.0-standard"   # Container Template for Devuan v3.0
osFedora="fedora-33-default"   # Container Template for Fedora v33
osGentoo="gentoo-current-default"   # Container Template for current Gentoo
osOpensuse="opensuse-15.2-default"   # Container Template for openSUSE v15.2
osUbuntu="ubuntu-20.04-standard"   # Container Template for Ubuntu v20.04
osAlpine3_11="alpine-3.11-default"   # Container Template for Alpine v3.11
osCentos7="centos-7-default"   # Container Template for Centos v7
osDebian9="debian-9.0-standard"   # Container Template for Debian v9
osFedora32="fedora-32-default"   # Container Template for Fedora v32
osUbuntu18="ubuntu-18.04-standard"   # Container Template for Ubuntu v18.04
osUbuntu20_10="ubuntu-20.10-standard"   # Container Template for Ubuntu v20.10

pve_Standardsoftware="parted smartmontools libsasl2-modules lxc-pve"  # Software that is installed afterwards on the server host
lxc_Standardsoftware="curl wget software-properties-common apt-transport-https gnupg2 net-tools"  #Software that is installed first on each LXC

##################### Script Variables #####################

# Divide by two so the dialogs take up half of the screen, which looks nice.
r=$(( rows / 2 ))
c=$(( columns / 2 ))
# Unless the screen is tiny
r=$(( r < 20 ? 20 : r ))
c=$(( c < 80 ? 80 : c ))

# check if Variable is valid URL
regexURL='^(https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'

##################### Script Variables #####################

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
otherDisks=$(lsblk -nd --output NAME | sed "s#$rootDisk##" | sed ':M;N;$!bM;s#\n# #' | sed 's# s#s#g' | sed 's# h#h#g' | sed ':M;N;$!bM;s#\n# #g')
CTTemplateDisk="local"

# Proxmox Variables
clusterfileFW="/etc/pve/firewall/cluster.fw"
hostfileFW="/etc/pve/nodes/$hostname/host.fw"
osname=buster

# Github Variables
configURL="http://pve.config.shiot.de"
containerURL="http://lxc.config.shiot.de"

# Container Variables
ctIDall=$(pct list | tail -n +2 | awk '{print $1}')

# SmartHome-IoT Variables
configFile="/root/.cfg_shiot"

##################### Selection menus #####################

# Language selctor
lng=(\
     "de" "Deutsch" \
     "en" "English" \
)

# Gateway selector
gw=( \
  "unifi" "Ubiquiti/UniFi DreamMachine Pro ${lng_or} CloudKey              " off \
  "avm" "AVM FRITZ!Box" off \
  "andere" "${lng_another_manufacturer}" off \
)

##################### Functions #####################

function createPassword() {
# Function generates a random secure password
  chars=({0..9} {a..z} {A..Z} "_" "%" "&" "+" "-")
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

function createAPIKey() {
# Function generates a random API key
  chars=({0..9} {a..f})
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

function switchToFunction() {
# Function calls a function
  $1
}

function getInformations() {
# Function asks the user about configurations in his network and saves them in a configuration file
  # Function saves variables to file
  function cfg_save() {
    echo "var_language=\"$var_language\"" > $configFile
    echo "var_robotname=\"$var_robotname\"" >> $configFile
    echo "var_gwmanufacturer=\"$var_gwmanufacturer\"" >> $configFile
    echo "var_servervlan=\"$var_servervlan\"" >> $configFile
    echo "var_smarthomevlan=\"$var_smarthomevlan\"" >> $configFile
    echo "var_guestvlan=\"$var_guestvlan\"" >> $configFile
    echo "var_rootmail=\"$var_rootmail\"" >> $configFile
    echo "var_mailserver=\"$var_mailserver\"" >> $configFile
    echo "var_mailport=\"$var_mailport\"" >> $configFile
    echo "var_mailusername=\"$var_mailusername\"" >> $configFile
    echo "var_mailpassword=\"$var_mailpassword\"" >> $configFile
    echo "var_senderaddress=\"$var_senderaddress\"" >> $configFile
    echo "var_mailtls=\"$var_mailtls\"" >> $configFile
    echo "var_nasip=\"$var_nasip\"" >> $configFile
    echo "var_synologynas=\"$var_synologynas\"" >> $configFile
  }
  # ask User for Script Language
  var_language=$(whiptail --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --menu "" ${r} ${c} 10 "${lng[@]}" 3>&1 1>&2 2>&3)
  # bind the chosen language
  source <(curl -sSL $configURL/lang/$var_language.lang)
  # generate a random 20 digit password
  networkrobotpw=$(createPassword 20)
  # give some Informations to the User
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_welcome" "$lng_start_info" ${r} ${c}
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_introduction" "$lng_introduction_text" ${r} ${c}
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_netrobot" "$lng_netrobot_text" ${r} ${c}
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_secure_password" "$lng_secure_password_text $networkrobotpw $lng_secure_password_text1" ${r} ${c}
  # ask for robot name
  var_robotname=$(whiptail --inputbox --ok-button "$lng_ok" --cancel-button "$lng_cancel" --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_netrobot_name" "$lng_netrobot_name_text" ${r} ${c} netrobot 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ "$exitstatus" = 1 ]]; then exit; fi
  # ask for robot password
  var_robotpw=$(whiptail --passwordbox --ok-button "$lng_ok" --cancel-button "$lng_cancel" --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_netrobot_password" "$lng_netrobot_password_text\n\n$lng_netrobot_password_text1" ${r} ${c} $networkrobotpw 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ "$exitstatus" = 1 ]]; then exit; fi
  if [[ $var_robotpw = "" ]]; then
    NEWT_COLORS='
      window=,red
      border=white,red
      textbox=white,red
      button=black,white
    ' \
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_pve_password" "$lng_password_error_text" ${r} ${c}
    exit
  fi
  # ask for Gateway Manufacturer
  var_gwmanufacturer=$(whiptail --radiolist --ok-button "$lng_ok" --cancel-button "$lng_cancel" --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_gateway_manufacturer" "$lng_gateway_manufacturer" ${r} ${c} 10 "${gw[@]}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ "$exitstatus" = 1 ]]; then exit; fi
  if [[ $var_gwmanufacturer == "andere" ]]; then
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_gateway_manufacturer" "$lng_another_manufacturer_text" ${r} ${c}
  fi
  if [[ $var_gwmanufacturer == "unifi" ]]; then
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_info" ${r} ${c}
    whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_ask" ${r} ${c}
    yesno=$?
    if [[ $yesno == 0 ]]; then
      var_servervlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_text_server" ${r} ${c} 100 3>&1 1>&2 2>&3)
      var_smarthomevlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_text_smarthome" ${r} ${c} 200 3>&1 1>&2 2>&3)
      var_guestvlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_text_guest" ${r} ${c} 300 3>&1 1>&2 2>&3)
    fi
  fi
  # ask for root E-Mailadress
  var_rootmail=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_root" "$lng_mail_root_text" ${r} ${c} 3>&1 1>&2 2>&3)
  # ask for mailserver
  var_mailserver=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server" "$lng_mail_server_text" ${r} ${c} 3>&1 1>&2 2>&3)
  # ask for mailserverport
  var_mailport=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server_port" "$lng_mail_server_port_text" ${r} ${c} 587 3>&1 1>&2 2>&3)
  # ask for mailserverusername
  var_mailusername=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server_user" "$lng_mail_server_user_text" ${r} ${c} 3>&1 1>&2 2>&3)
  # ask for mailserveruserpassword
  var_mailpassword=$(whiptail --passwordbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server_user_password" "$lng_mail_server_user_password_text \"$var_mailusername\" $lng_mail_server_password_text1" ${r} ${c} 3>&1 1>&2 2>&3)
  # ask for sending adress
  var_senderaddress=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_sender" "$lng_mail_sender_text" ${r} ${c} "notify@$(echo "$var_rootmail" | cut -d\@ -f2)" 3>&1 1>&2 2>&3)
  whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_tls" "$lng_mail_tls_text" ${r} ${c}
  yesno=$?
  if [[ $yesno == 0 ]]; then
    var_mailtls=yes
  else
    var_mailtls=no
  fi
  whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_configuration" "$lng_nas_ask" ${r} ${c}
  yesno=$?
  if [[ $yesno == 0 ]]; then
    function pingNAS() {
      var_nasip=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_ip" "$lng_nas_ip_text" ${r} ${c} 3>&1 1>&2 2>&3)
      if ping -c 1 "$var_nasip" > /dev/null 2>&1; then
        export nasexists=true
        {
          for ((i = 98 ; i <= 100 ; i+=1)); do
            sleep 0.5
            echo $i
          done
        } | whiptail --gauge "$lng_nas_ip_check" 6 ${c} 0
      else
        {
          for ((i = 98 ; i <= 100 ; i+=1)); do
            sleep 0.5
            echo $i
          done
        } | whiptail --gauge "$lng_nas_ip_check" 6 ${c} 0
        whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_ip" "$lng_nas_ip_error" ${r} ${c}
        pingNAS
      fi
    }
    pingNAS
    var_nasip=$var_nasip
    whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_manufacturer" "$lng_nas_manufacturer_text" ${r} ${c}
    yesno=$?
    if [[ $yesno == 1 ]]; then var_synologynas=true; fi
    whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_folder_config" "$lng_nas_folder_config_text \"$varrobotname\" $lng_nas_folder_config_text1 \"$varrobotname\" $lng_nas_folder_config_text2" ${r} ${c}
    yesno=$?
    if [[ $yesno == 1 ]]; then
      NEWT_COLORS='
        window=,red
        border=white,red
        textbox=white,red
        button=black,white
      ' \
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_folder_config" "$lng_nas_folder_error" ${r} ${c}
      exit
    fi
  fi
  cfg_save
  return 0
}

function configPVE() {
# Function configures Proxmox based on User Inputs, if this Script runs the First Time
  function cfg_email() {
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

      echo -e "XXX\n99\n$lng_pve_configuration_text\nXXX"
    } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_configuration" --gauge "$lng_pve_configuration_text" 6 ${c} 0

    # Test email settings
    echo -e "$lng_mail_configuration_test_message" | mail -s "[pve] $lng_mail_configuration_test_message_subject" "$var_rootmail"
    whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_configuration_test" "$lng_mail_configuration_test_text\n\n$var_rootmail\n\nWurde die E-Mail erfolgreich zugestellt (Es kann je nach Anbieter bis zu 15 Minuten dauern)?" ${r} ${c}
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
      whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_configuration_test" "$lng_mail_configuration_test_text\n\n$var_rootmail\n\nWurde die E-Mail erfolgreich zugestellt (Es kann je nach Anbieter bis zu 15 Minuten dauern)?" ${r} ${c}
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
    return 0
  }

  function cfg_HDD() {
  # Function configures e-mail notification for S.M.A.R.T. values of the system hard disk and configures a second hard disk, if available.
    # Set email notification about system hard disk errors, check every 12 hours
    sed -i 's+#enable_smart="/dev/hda /dev/hdb"+enable_smart="/dev/'"$rootDisk"'"+' /etc/default/smartmontools
    sed -i 's+#smartd_opts="--interval=1800"+smartd_opts="--interval=43200"+' /etc/default/smartmontools
    echo "start_smartd=yes" > /etc/default/smartmontools
    sed -i 's+DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner+#DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner+' /etc/smartd.conf
    sed -i 's+# /dev/sda -a -d sat+/dev/'"$rootDisk"' -a -d sat+' /etc/smartd.conf
    sed -i 's+#/dev/sda -d scsi -s L/../../3/18+/dev/'"$rootDisk"' -d sat -s L/../../1/02 -m root+' /etc/smartd.conf
    systemctl start smartmontools
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
              CTTemplateDisk="data"

              # Set email notification about hard disk errors, check every 12 hours
              sed -i 's+enable_smart="/dev/'"$rootDisk"'"+enable_smart="/dev/'"$rootDisk"' /dev/'"$otherDisks"'"+' /etc/default/smartmontools
              sed -i 's+/dev/'"$rootDisk"' -a -d sat+/dev/'"$rootDisk"' -a -d sat\n/dev/'"$otherDisks"' -a -d sat+' /etc/smartd.conf
              sed -i 's+#/dev/sdb -d scsi -s L/../../7/01+/dev/'"$otherDisks"' -d sat -s L/../../1/03 -m root+' /etc/smartd.conf
              systemctl restart smartmontools
            fi
          fi
        else
          CTTemplateDisk="data"
        fi
      fi
    } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_configuration" --gauge "$lng_pve_configuration_text" 6 ${c} 0
    return 0
  }

  function cfg_NAS () {
  # Function mounts, if specified, the NAS as backup drive in Proxmox and makes it available to the containers as backup and media drive
    if [ ! -z $var_nasip ]; then
      pvesm add cifs backups --server "$var_nasip" --share "backups" --username "$var_robotname" --password "$var_robotpw" --content backup
      pvesh create /pools --poolid BackupPool --comment "$lng_lxcpool_comment"
      echo "0 3 * * *   root   vzdump --compress zstd --mailto root --mailnotification always --exclude-path /mnt/ --exclude-path /media/ --mode snapshot --quiet 1 --pool BackupPool --maxfiles 6 --storage backups" >> /etc/cron.d/vzdump
    fi
    return 0
  }

  function cfg_Firewall() {
  # Function configures and activates the Proxmox firewall
    mkdir -p /etc/pve/firewall
    mkdir -p /etc/pve/nodes/$hostname
    # Cluster level firewall
    echo -e "[OPTIONS]\n\nenable: 1\n\n[IPSET network] # $lng_homenetwork\n$networkIP.0/$cidr\n\n[IPSET pnetwork] # $lng_privatenetworks\n10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16\n\n[RULES]\n\nGROUP proxmox\n\n[group proxmox]\n\nIN SSH(ACCEPT) -source +network -log nolog\nIN ACCEPT -source +network -p tcp -dport 8006 -log nolog\n\n" > $clusterfileFW
    # Host level Firewall
    echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP proxmox\n\n" > $hostfileFW
    return 0
  }

  function cfg_LXC() {
  # Function asks the user which containers to install
    if [ -z $var_nasip ]; then
      source <(curl -sSL $containerURL/nonaslxc.list)
    else
      source <(curl -sSL $containerURL/naslxc.list)
    fi
    var_lxcchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_lxc_configuration" --title "$lng_lxc_configuration_title" "$lng_lxc_configuration_text" 20 80 10 "${lxclist[@]}" 3>&1 1>&2 2>&3)
    var_lxcchoice=$(echo $var_lxcchoice | sed -e 's#\"##g')
    whiptail --yesno --backtitle "© 2021 - SmartHome-IoT.net - $lng_lxc_configuration" --title "$lng_end_info" "$lng_end_info_text" ${r} ${c}
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_finish" --title "$lng_finish" "$lng_finish_text" ${r} ${c}
      return
    else
      NEWT_COLORS='
        window=,red
        border=white,red
        textbox=white,red
        button=black,white
      ' \
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_abort" --title "$lng_abort" "$lng_abort_text" ${r} ${c}
      exit
    fi
    return 0
  }
  cfg_email
  cfg_HDD
  cfg_NAS
  cfg_Firewall
  cfg_LXC
}

function createLXC() {
# Function creates the LXC container
  # check if HDD for Container Templates has been changed
  if [ $(pvesm status | grep -c data) -eq 1 ]; then CTTemplateDisk="data"; fi
  # Load container language file
  source <(curl -sSL $containerURL/$lxchostname/lang/$var_language.lang)
  function lxc_SQLSecure () {
    # Function configures SQL secure in LXC Containers
    SECURE_MYSQL=$(expect -c "
    set timeout 3
    spawn mysql_secure_installation
    expect \"Press y|Y for Yes, any other key for No:\"
    send \"n\r\"
    expect \"New password:\"
    send \"${ctRootpw}\r\"
    expect \"Re-enter new password:\"
    send \"${ctRootpw}\r\"
    expect \"Remove anonymous users?\"
    send \"y\r\"
    expect \"Disallow root login remotely?\"
    send \"y\r\"
    expect \"Remove test database and access to it?\"
    send \"y\r\"
    expect \"Reload privilege tables now?\"
    send \"y\r\"
    expect eof
    ")

    pct exec $ctID -- bash -ci "apt-get install -y expect > /dev/null 2>&1"
    pct exec $ctID -- bash -ci "echo \"${SECURE_MYSQL}\" > /dev/null 2>&1"
    pct exec $ctID -- bash -ci "apt-get purge -y expect > /dev/null 2>&1"
    return 0
  }

  {
    # Generates ID and IP-Address for the container to be created
    echo -e "XXX\n7\n$lng_lxc_setup_text_idip\nXXX"
    if [ $(pct list | grep -c 100) -eq 0 ]; then
      ctID=100
      ctIP=$networkIP.$(( $(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f4) + 5 ))
    else
      ctID=$(( $(pct list | tail -n1 | awk '{print $1}') + 1 ))
      ctIP=$networkIP.$(( $(lxc-info $(pct list | tail -n1 | awk '{print $1}') -iH | grep "$networkIP" | cut -d. -f4) + 1 ))
    fi

    # Loads the container template from the Internet if not available and saves it for further use
    echo -e "XXX\n14\n$lng_lxc_setup_text_template_download\nXXX"
    pveam update > /dev/null 2>&1
    if [[ $ctTemplate == "osDevuan" ]]; then
      ctOstype="unmanaged"
    else
      ctOstype=$(pveam available | grep "${!ctTemplate}" | awk '{print $2}' | cut -d- -f1)
    fi
    if [ $(pveam list "$CTTemplateDisk" | grep -c "${!ctTemplate}") -eq 0 ]; then
      echo -e "XXX\n17\n$lng_lxc_setup_text_template_download1\nXXX"
      pveam download $CTTemplateDisk $(pveam available | grep "${!ctTemplate}" | awk '{print $2}') > /dev/null 2>&1
    fi

    # Checks if tenplatedisk has changed
    if [[ $CTTemplateDisk == "local" ]]; then rootfs="local-lvm"; else rootfs=$CTTemplateDisk; fi

    # Create Container from Template
    echo -e "XXX\n25\n$lng_lxc_setup_text_container_install\nXXX"
    if [[ $features == "" ]]; then
      pct create $ctID \
        $CTTemplateDisk:vztmpl/$(pveam available | grep "${!ctTemplate}" | awk '{print $2}') \
        --ostype $ctOstype \
        --hostname "$lxchostname" \
        --password "$ctRootpw" \
        --rootfs $rootfs:$hddsize \
        --cores $cpucores \
        --memory $memory \
        --swap $swap \
        --net0 bridge=vmbr0,name=eth0,ip="$ctIP"/$cidr,gw="$gatewayIP",ip6=manual,firewall=1 \
        --onboot 1 \
        --force 1 \
        --unprivileged $unprivileged \
        --start 1 > /dev/null 2>&1
    else
      pct create $ctID \
        $CTTemplateDisk:vztmpl/$(pveam available | grep "${!ctTemplate}" | awk '{print $2}') \
        --ostype $ctOstype \
        --hostname "$lxchostname" \
        --password "$ctRootpw" \
        --rootfs $rootfs:$hddsize \
        --cores $cpucores \
        --memory $memory \
        --swap $swap \
        --net0 bridge=vmbr0,name=eth0,ip="$ctIP"/$cidr,gw="$gatewayIP",ip6=manual,firewall=1 \
        --onboot 1 \
        --force 1 \
        --unprivileged $unprivileged \
        --start 1 \
        --features "$features" > /dev/null 2>&1
    fi
    sleep 5
    pct exec $ctID -- bash -c "sed -i 's+    SendEnv LANG LC_*+#   SendEnv LANG LC_*+g' /etc/ssh/ssh_config"    # Disable SSH client option SendEnv LC_* because errors occur during automatic processing
    # Mounted the NAS to container if exist and is needed
    if [ ! -z $var_nasip ] && $nasneeded; then
      echo -e "XXX\n32\n$lng_lxc_create_text_nas\nXXX"
      pct exec $ctID -- bash -ci "mkdir -p /media"
      pct exec $ctID -- bash -ci "mkdir -p /mnt/backup"
      pct exec $ctID -- bash -ci "echo \"//$var_nasip/media  /media  cifs  credentials=/home/.smbmedia,uid=1000,gid=1000  0  0\" >> /etc/fstab"
      pct exec $ctID -- bash -ci "echo \"//$var_nasip/backups  /mnt/backup  cifs  credentials=/home/.smbbackup,uid=1000,gid=1000  0  0\" >> /etc/fstab"
      pct exec $ctID -- bash -ci "echo -e \"username=$var_robotname\npassword=$var_robotpw\" > /home/.smbmedia"
      pct exec $ctID -- bash -ci "echo -e \"username=$var_robotname\npassword=$var_robotpw\" > /home/.smbbackup"
      pct exec $ctID -- bash -ci "mount -a"
    fi
    pct shutdown $ctID --timeout 5
    sleep 15
    # Mounted the DVB-Card to container if exist and is needed
    if [ $(ls -la /dev/dvb/ | grep -c adapter0) -eq 1 ] && $dvbneeded; then
      echo -e "XXX\n39\n$lng_lxc_create_text_dvb\nXXX"
      echo "lxc.cgroup.devices.allow: c $(ls -la /dev/dvb/adapter0 | grep video | head -n1 | awk '{print $5}' | cut -d, -f1):* rwm" >> /etc/pve/lxc/$ctID.conf
      echo "lxc.mount.entry: /dev/dvb dev/dvb none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
    fi
    # Mounted the VGA-Card to container if exist and is needed
    if [ $(ls -la /dev/dri/card0 | grep -c video) -eq 1 ] && $vganeeded; then
      echo -e "XXX\n45\n$lng_lxc_create_text_vga\nXXX"
      echo "lxc.cgroup.devices.allow: c $(ls -la /dev/dri | grep video | head -n1 | awk '{print $5}' | cut -d, -f1):* rwm" >> /etc/pve/lxc/$ctID.conf
      echo "lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
      echo "lxc.mount.entry: /dev/dri/render$(ls -la /dev/dri | grep render | head -n1 | awk '{print $10}' | cut -d'r' -f3) dev/dri/render$(ls -la /dev/dri | grep render | head -n1 | awk '{print $10}' | cut -d'r' -f3) none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
    fi
    pct start $ctID
    sleep 10
    echo -e "XXX\n51\n$lng_lxc_setup_text_container_update\nXXX"
    pct exec $ctID -- bash -c "apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1"
    echo -e "XXX\n58\n$lng_lxc_setup_text_software_install\nXXX"
    for package in $lxc_Standardsoftware; do
      pct exec $ctID -- bash -c "apt-get install -y $package > /dev/null 2>&1"
    done
    # Create specific folders in the file system    
    echo -e "XXX\n64\n$lng_lxc_create_text_file_structure\nXXX"
    for folder in $containerFolder; do
      pct exec $ctID -- bash -c "mkdir -p $folder"
    done
    # Commands before the software installation starts from commandsFirst Variable
    if [ ! -z $commandsFirst ]; then
      echo -e "XXX\n68\n$lng_lxc_create_text_package_install\nXXX"
      for f_command in $commandsFirst; do
        pct exec $ctID -- bash -c "$f_command"
      done
    fi
    # Install Software from containerSoftware Variable
    echo -e "XXX\n73\n$lng_lxc_create_text_software_install\nXXX"
    pct exec $ctID -- bash -c "apt-get update"
    for package in $containerSoftware; do
      pct exec $ctID -- bash -c "apt-get install -y $package > /dev/null 2>&1"
    done
    # Commands after the software installation starts from commandsSecond Variable
    if [ ! -z $commandsSecond ]; then
      echo -e "XXX\n73\n$lng_lxc_create_text_software_configuration\nXXX"
      for s_command in $commandsSecond; do
        pct exec $ctID -- bash -c "$s_command"
      done
    fi
    # Functions executed from the template file after the container installation
    if [ ! -z $functions ]; then
      echo -e "XXX\n78\n$lng_lxc_create_text_final_tasks\nXXX"
      pct reboot $ctID --timeout 5
      sleep 15
      for fnc in $functions; do
        functions
      done
    fi
    # Create Container description, you can find it on Proxmox WebGUI
    echo -e "XXX\n84\n$lng_lxc_create_text_description\nXXX"
    if [ ! -z $var_nasip ] && $nasneeded; then
      nasDescription=$(echo -e "\n\nNAS\nMediaFolder:  /media\nBackupFolder: /mnt/backup")
    else
      nasDescription=""
    fi
    # # Commands to be executes in the Host (Proxmox) shell after Container creation
    if [ ! -z $pveCommands ]; then
      echo -e "XXX\n92\n$lng_lxc_create_finish\nXXX"
      for command in $pveCommands; do
        $command
      done
    fi
    pct set $ctID --description $'Shell\nBenutzer:  root\nPasswort:  $ctRootpw\n\n'"$containerDescription $nasDescription"
    pct reboot $ctID --timeout 5
    sleep 15
    # Create Firewall Rules for Container
    echo -e "XXX\n97\n$lng_lxc_create_text_firewall\nXXX"
    echo -e "\n[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\n" >> $clusterfileFW    # This Line will create the Firewall Goup Containername - don't change it
    for i in "${!fw[@]}"; do
      echo -e "IN ACCEPT -source +${fwNetwork[i]} -p ${fwProtocol[i]} -dport ${fwPort[i]} # ${fwDescription[i]} -log nolog\n" >> $clusterfileFW
    done
    echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw    # Allow generated Firewallgroup, don't change it
    # Insert all VMs in Backup Pool
    pvesh set /pools/BackupPool -vms "$ctID"
  } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_lxc_setup" --title "$ctID - $lxchostname" --gauge "$lng_lxc_setup_text" 6 ${c} 0
  return 0
}

if [ -f $configFile ]; then
  # Configfile exist
  source $configFile
  source <(curl -sSL $configURL/lang/$var_language.lang)
  var_robotpw=$(whiptail --passwordbox --ok-button "$lng_ok" --cancel-button "$lng_cancel" --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_netrobot_password" "$lng_netrobot_password_text" ${r} ${c} 3>&1 1>&2 2>&3)
  
  if [ ! -z $1 ] && [ ! -z $2 ]; then
    function checkURL() {
      if [[ ! $containerURL =~ $regexURL ]]; then
        NEWT_COLORS='
          window=,red
          border=white,red
          textbox=white,red
          button=black,white
        ' \
        containerURL=$(whiptail --inputbox --ok-button "$lng_ok" --cancel-button "$lng_cancel" --backtitle "© 2021 - SmartHome-IoT.net - Container URL" --title "$lng_error" "$lng_url_error_text" ${r} ${c} $containerURL 3>&1 1>&2 2>&3)
        checkURL
      fi
    }
    containerURL=$2
    checkURL
    var_lxcchoice=$1
    for lxcName in $var_lxcchoice; do
    # Load Container Template from Internet
      source <(curl -sSL $containerURL/$lxcName/install.template)
      # Start Container creation
      createLXC
    done
  elif [ ! -z $1 ]; then
    var_lxcchoice=$1
    for lxcName in $var_lxcchoice; do
    # Load Container Template from Internet
      source <(curl -sSL $containerURL/$lxcName/install.template)
      # Start Container creation
      createLXC
    done
  else
    if [ -z $var_nasip ]; then
      source <(curl -sSL $containerURL/nonaslxc.list)
    else
      source <(curl -sSL $containerURL/naslxc.list)
    fi
    var_lxcchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_lxc_configuration" --title "$lng_lxc_configuration_title" "$lng_lxc_configuration_text" 20 80 10 "${lxclist[@]}" 3>&1 1>&2 2>&3)
    var_lxcchoice=$(echo $var_lxcchoice | sed -e 's#\"##g')
    whiptail --yesno --backtitle "© 2021 - SmartHome-IoT.net - $lng_lxc_configuration" --title "$lng_end_info" "$lng_end_info_text" ${r} ${c}
    exitstatus=$?
    if [ $exitstatus = 1 ]; then
      NEWT_COLORS='
        window=,red
        border=white,red
        textbox=white,red
        button=black,white
      ' \
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_abort" --title "$lng_abort" "$lng_abort_text" ${r} ${c}
      exit
    fi
    for lxcName in $var_lxcchoice; do
    # Load Container Template from Internet
      source <(curl -sSL $containerURL/$lxcName/install.template)
      # Start Container creation
      createLXC
    done
  fi
  exit
fi

getInformations
configPVE
createLXC
