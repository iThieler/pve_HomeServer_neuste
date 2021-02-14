#!/bin/bash

osUbuntu="ubuntu-20.04"         # Container Template für Ubuntu v20.04
osUbuntu18="ubuntu-18.04"       # Container Template für Ubuntu v18.04
osDebian="debian-10-standard"   # Container Template für Debian v10
osDebian9="debian-9.0-standard"   # Container Template für Debian v9

##################### Script Variables #####################

# Colorize the Shell
ok="[\e[1;32mOK\e[0m]   "
info="[\e[1;33mINFO\e[0m] "
error="[\e[1;31mERROR\e[0m]"
question="[\e[1;34mFRAGE\e[0m]"
yesno="\e[1;34mJ\e[0m = Ja oder \e[1;34mN\e[0m = Nein:"
tick="[\e[1;32m✓\e[0m]"
cross="[\e[1;31m✗\e[0m]"
line="[\e[1;33m-\e[0m]"

# Divide by two so the dialogs take up half of the screen, which looks nice.
r=$(( rows / 2 ))
c=$(( columns / 2 ))
# Unless the screen is tiny
r=$(( r < 20 ? 20 : r ))
c=$(( c < 70 ? 70 : c ))

# Variables are needed for calculations in the script
gatewayIP=$(ip r | grep default | cut -d" " -f3)
pveIP=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1)
cidr=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f2)
networkIP=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f1,2,3)
rootDisk=$(lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"' | cut -d' ' -f2 | cut -d\" -f2 | sed 's#[0-9]*$##')
otherDisks=$(lsblk -nd --output NAME | sed "s#$rootDisk##" | sed ':M;N;$!bM;s#\n# #' | sed 's# s#s#g' | sed 's# h#h#g' | sed ':M;N;$!bM;s#\n# #g')
ctIDall=$(pct list | tail -n +2 | awk '{print $1}')
downloadPath="local"
ctStandardsoftware="curl wget software-properties-common gnupg2 net-tools"
rawGitHubURL="https://raw.githubusercontent.com/shiot/prepve/master"
configFile="/root/.shiot_config"
fqdn=$(hostname -f)
hostname=$(hostname)
osname=buster

##################### Functions #####################

function shellLogo() {
  echo "                                                                                                                                                   "
  echo "                                                                                                                                                   "
  echo " .d8888b.                                 888    888    888                                      8888888     88888888888                    888    "
  echo "d88P  Y88b                                888    888    888                                        888           888                        888    "
  echo "Y88b.                                     888    888    888                                        888           888                        888    "
  echo " 'Y888b.   88888b.d88b.   8888b.  888d888 888888 8888888888  .d88b.  88888b.d88b.   .d88b.         888   .d88b.  888      88888b.   .d88b.  888888 "
  echo "    'Y88b. 888 '888 '88b     '88b 888P'   888    888    888 d88''88b 888 '888 '88b d8P  Y8b        888  d88''88b 888      888 '88b d8P  Y8b 888    "
  echo "      '888 888  888  888 .d888888 888     888    888    888 888  888 888  888  888 88888888 888888 888  888  888 888      888  888 88888888 888    "
  echo "Y88b  d88P 888  888  888 888  888 888     Y88b.  888    888 Y88..88P 888  888  888 Y8b.            888  Y88..88P 888  d8b 888  888 Y8b.     Y88b.  "
  echo " 'Y8888P'  888  888  888 'Y888888 888      'Y888 888    888  'Y88P'  888  888  888  'Y8888       8888888 'Y88P'  888  Y8P 888  888  'Y8888   'Y888 "
  echo "                                                                                                                                                   "
  echo "                                                                                                                                                   "
}

function createPassword() {
  chars=({0..9} {a..z} {A..Z} "_" "%" "&" "+" "-")
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

function selectLanguage() {
  wget -rqO /root/lng.conf $rawGitHubURL/config/lng.conf
  source /root/lng.conf
  lang=$(whiptail --backtitle "© 2021 - SmartHome-IoT.net" --menu "Wähle / Choose" ${r} ${c} 10 "${lng[@]}" 3>&1 1>&2 2>&3)
  wget -qO /root/lang $rawGitHubURL/lang/$lang
  source /root/lang
  echo "lang=\"$lang\"" >> $configFile
  return 0
}

function startupInfo() {
  networkrobotpw=$(createPassword 20)
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_welcome" --scrolltext "$lng_start_info" ${r} ${c}
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_introduction" "$lng_introduction_text" ${r} ${c}
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_netrobot" "$lng_netrobot_text" ${r} ${c}
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_secure_password" "$lng_secure_password_text $networkrobotpw $lng_secure_password_text1" ${r} ${c}
  return 0
}

function pveConfig() {
  {
    # Entfernt das Enterprise Repository und ersetzt es durch das Community Repository
    echo -e "XXX\n0\n$lng_pve_configuration_community\nXXX"
    if [ -f "/etc/apt/sources.list.d/pve-enterprise.list" ]; then
      rm /etc/apt/sources.list.d/pve-enterprise.list
    fi
    if [ ! -f "/etc/apt/sources.list.d/pve-community.list" ]; then
      echo "deb http://download.proxmox.com/debian/pve $osname pve-no-subscription" > /etc/apt/sources.list.d/pve-community.list
    fi
    if [ ! -f "/etc/apt/sources.list.d/ceph.list" ]; then
      echo "deb http://download.proxmox.com/debian/ceph-octopus $osname main" > /etc/apt/sources.list.d/ceph.list
    fi

    # Führt ein Systenupdate aus und installiert für dieses Script benötigte Software
    echo -e "XXX\n32\n$lng_pve_configuration_update\nXXX"
    apt-get update > /dev/null 2>&1 && apt-get upgrade -y 2>&1 >/dev/null && apt-get dist-upgrade -y 2>&1 >/dev/null && pveam update 2>&1 >/dev/null
    echo -e "XXX\n84\n$lng_pve_configuration_install\nXXX"
    softwaretoinstall="parted smartmontools libsasl2-modules lxc-pve"
    for package in $softwaretoinstall; do
      apt-get install -y "$package" > /dev/null 2>&1
    done

    # Aktiviere S.M.A.R.T. support auf Systemfestplatte
    echo -e "XXX\n68\n$lng_pve_configuration_smart\nXXX"
    if [ $(smartctl -a /dev/"$rootDisk" | grep -c "SMART support is: Enabled") -eq 0 ]; then
      smartctl -s on -a /dev/"$rootDisk"
    fi

    # Aktiviere Paketweiterleitung an Container (wird benötigt um Docker in Containern laufen zu lassen)
    echo -e "XXX\n99\n$lng_pve_configuration_forward\nXXX"
    sed -i 's+#net.ipv4.ip_forward=1+net.ipv4.ip_forward=1+' /etc/sysctl.conf
    sed -i 's+#net.ipv6.conf.all.forwarding=1+net.ipv6.conf.all.forwarding=1+' /etc/sysctl.conf
  } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_welcome" --title "$lng_pve_configuration" --gauge "$lng_pve_configuration_text" 6 70 0
  return 0
}

function networkConfig() {
  varpverootpw=$(whiptail --passwordbox --ok-button "$lng_ok" --cancel-button "$lng_cancel" --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_pve_password" "$lng_pve_password_text" ${r} ${c} 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ "$exitstatus" = 1 ]]; then exit; fi
  if [[ $varpverootpw = "" ]]; then
    NEWT_COLORS='
      window=,red
      border=white,red
      textbox=white,red
      button=black,white
    ' \
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_pve_password" "$lng_password_error_text" ${r} ${c}
    exit
  fi
  varrobotname=$(whiptail --inputbox --ok-button "$lng_ok" --cancel-button "$lng_cancel" --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_netrobot_name" "$lng_netrobot_name_text" ${r} ${c} netrobot 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ "$exitstatus" = 1 ]]; then exit; fi
  varrobotpw=$(whiptail --passwordbox --ok-button "$lng_ok" --cancel-button "$lng_cancel" --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_netrobot_password" "$lng_netrobot_password_text" ${r} ${c} $networkrobotpw 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ "$exitstatus" = 1 ]]; then exit; fi
  if [[ $varrobotpw = "" ]]; then
    NEWT_COLORS='
      window=,red
      border=white,red
      textbox=white,red
      button=black,white
    ' \
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_pve_password" "$lng_password_error_text" ${r} ${c}
    exit
  fi
  wget -qO /root/gw.conf $rawGitHubURL/config/gw.conf
  source /root/gw.conf
  vargwmanufacturer=$(whiptail --radiolist --ok-button "$lng_ok" --cancel-button "$lng_cancel" --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_gateway_manufacturer" "$lng_gateway_manufacturer" ${r} ${c} 10 "${gw[@]}" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ "$exitstatus" = 1 ]]; then exit; fi
  if [[ $vargwmanufacturer == "andere" ]]; then
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_gateway_manufacturer" "$lng_another_manufacturer_text" ${r} ${c}
  fi
  if [[ $vargwmanufacturer == "unifi" ]]; then
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_info" ${r} ${c}
    whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_ask" ${r} ${c}
    yesno=$?
    if [[ $yesno == 0 ]]; then
      vlanexists=y
      varservervlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_text_server" ${r} ${c} 1 3>&1 1>&2 2>&3)
      varsmarthomevlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_text_smarthome" ${r} ${c} 10 3>&1 1>&2 2>&3)
      varguestvlan=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_network_infrastructure" --title "$lng_vlan" "$lng_vlan_text_guest" ${r} ${c} 100 3>&1 1>&2 2>&3)
    else
      vlanexists=n
    fi
  fi
  echo "varrobotname=\"$varrobotname\"" >> $configFile
  echo "vargwmanufacturer=\"$vargwmanufacturer\"" >> $configFile
  if [[  $vlanexists == "y" ]]; then
    echo "vlanexists=\"$vlanexists\"" >> $configFile
    echo "varservervlan=\"$varservervlan\"" >> $configFile
    echo "varsmarthomevlan=\"$varsmarthomevlan\"" >> $configFile
    echo "varguestvlan=\"$varguestvlan\"" >> $configFile
  fi
  return 0
}

function emailConfig() {
  function configEmail() {
    if [ $(grep -crnwi '/etc/default/smartmontools' -e '43200') -eq 0 ]; then
      {
        if grep "root:" /etc/aliases; then
          sed -i "s/^root:.*$/root: $varrootmail/" /etc/aliases
        else
          echo "root: $varrootmail" >> /etc/aliases
        fi
        echo "root $varsenderaddress" >> /etc/postfix/canonical
        chmod 600 /etc/postfix/canonical

        # Vorbereitung für Passworthash
        echo [$varmailserver]:"$varmailport" "$varmailusername":"$varmailpassword" >> /etc/postfix/sasl_passwd
        chmod 600 /etc/postfix/sasl_passwd 

        # Mailserver in main.cf hinzufügen
        sed -i "/#/!s/\(relayhost[[:space:]]*=[[:space:]]*\)\(.*\)/\1"[$varmailserver]:"$varmailport""/"  /etc/postfix/main.cf

        # TLS-Einstellungen prüfen
        postconf smtp_use_tls=$vartls

        # Prüfen auf Passwort-Hash-Eingabe
        if ! grep "smtp_sasl_password_maps" /etc/postfix/main.cf; then
          postconf smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd > /dev/null 2>&1
        fi

        #Überprüfung auf Zertifikat
        if ! grep "smtp_tls_CAfile" /etc/postfix/main.cf; then
          postconf smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt > /dev/null 2>&1
        fi

        # Hinzufügen von sasl-Sicherheitsoptionen und beseitigt standardmäßige Sicherheitsoptionen, die nicht mit Google Mail kompatibel sind
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

      } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_configuration" --gauge "$lng_pve_configuration_text" 6 70 0

      # Testen der E-Mail Einstellungen
      echo -e "$lng_mail_configuration_test_message" | mail -s "[pve] $lng_mail_configuration_test_message_subject" "$varrootmail"
      whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_configuration_test" "$lng_mail_configuration_test_text\n\n$varrootmail\n\nWurde die E-Mail erfolgreich zugestellt (Es kann je nach Anbieter bis zu 15 Minuten dauern)?" ${r} ${c}
      yesno=$?
      if [[ $yesno == 1 ]]; then
        NEWT_COLORS='
          window=,red
          border=white,red
          textbox=white,red
          button=black,white
        ' \
        whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_error" "$lng_mail_error_text" ${r} ${c}
        if grep "SMTPUTF8 is required" "/var/log/mail.log"; then
          if ! grep "smtputf8_enable = no" /etc/postfix/main.cf; then
            postconf smtputf8_enable=no
            postfix reload
          fi
        fi
        echo -e "$lng_mail_configuration_test_message" | mail -s "[pve] $lng_mail_configuration_test_message_subject" "$varrootmail"
        whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_configuration_test" "$lng_mail_configuration_test_text\n\n$varrootmail\n\nWurde die E-Mail erfolgreich zugestellt (Es kann je nach Anbieter bis zu 15 Minuten dauern)?" ${r} ${c}
        yesno=$?
        if [[ $yesno == 1 ]]; then
          NEWT_COLORS='
            window=,red
            border=white,red
            textbox=white,red
            button=black,white
          ' \
          whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_error" "$lng_mail_error_text1" ${r} ${c}
        fi
      fi

      # E-Mailbenachrichtigung über Festplattenfehler, prüfung alle 12 Stunden
      sed -i 's+#enable_smart="/dev/hda /dev/hdb"+enable_smart="/dev/'"$rootDisk"'"+' /etc/default/smartmontools
      sed -i 's+#smartd_opts="--interval=1800"+smartd_opts="--interval=43200"+' /etc/default/smartmontools
      echo "start_smartd=yes" > /etc/default/smartmontools
      sed -i 's+DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner+#DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner+' /etc/smartd.conf
      sed -i 's+# /dev/sda -a -d sat+/dev/'"$rootDisk"' -a -d sat+' /etc/smartd.conf
      sed -i 's+#/dev/sda -d scsi -s L/../../3/18+/dev/'"$rootDisk"' -d sat -s L/../../1/02 -m root+' /etc/smartd.conf
      systemctl start smartmontools
    fi
    return 0
  }

  varrootmail=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_root" "$lng_mail_root_text" ${r} ${c} 3>&1 1>&2 2>&3)
  varmailserver=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server" "$lng_mail_server_text" ${r} ${c} 3>&1 1>&2 2>&3)
  varmailport=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server_port" "$lng_mail_server_port_text" ${r} ${c} 587 3>&1 1>&2 2>&3)
  varmailusername=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server_user" "$lng_mail_server_user_text" ${r} ${c} 3>&1 1>&2 2>&3)
  varmailpassword=$(whiptail --passwordbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_server_user_password" "$lng_mail_server_user_password_text \"$varmailusername\" $lng_mail_server_password_text1" ${r} ${c} 3>&1 1>&2 2>&3)
  varsenderaddress=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_sender" "$lng_mail_sender_text" ${r} ${c} "notify@$(echo "$varrootmail" | cut -d\@ -f2)" 3>&1 1>&2 2>&3)
  whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_mail_configuration" --title "$lng_mail_tls" "$lng_mail_tls_text" ${r} ${c}
  yesno=$?
  if [[ $yesno == 0 ]]; then
    vartls=yes
  else
    vartls=no
  fi
  # Executes the notification configuration
  configEmail
  echo "varrootmail=\"$varrootmail\"" >> $configFile
  echo "varsenderaddress=\"$varsenderaddress\"" >> $configFile
  return 0
}

function nasConfig() {
  function configStorage() {
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
              downloadPath="data"

              # E-Mailbenachrichtigung über Festplattenfehler, prüfung alle 12 Stunden
              sed -i 's+enable_smart="/dev/'"$rootDisk"'"+enable_smart="/dev/'"$rootDisk"' /dev/'"$otherDisks"'"+' /etc/default/smartmontools
              sed -i 's+/dev/'"$rootDisk"' -a -d sat+/dev/'"$rootDisk"' -a -d sat\n/dev/'"$otherDisks"' -a -d sat+' /etc/smartd.conf
              sed -i 's+#/dev/sdb -d scsi -s L/../../7/01+/dev/'"$otherDisks"' -d sat -s L/../../1/03 -m root+' /etc/smartd.conf
              systemctl restart smartmontools
              confignotemailcontent="${confignotemailcontent}Eingebundene Festplatten\nFestplatten Typ: SSD\nFestplatte: /dev/$otherDisks\nMountpfad: /mnt/data\nProxmox Name: data\n\n\n"
            fi
          fi
        else
          downloadPath="data"
        fi
        if [ $(pvesm status | grep -c data) -eq 1 ]; then downloadPath="data"; fi
      fi
      if [ $(pvesm status | grep 'backups' | grep -c 'active') -eq 0 ] && [[ $varnasexists == "y" ]]; then
        echo -e "XXX\n87\n$lng_nas_configuration_nas\nXXX"
        pvesm add cifs backups --server "$varnasip" --share "backups" --username "$varrobotname" --password "$varrobotpw" --content backup
      fi
    } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_configuration" --gauge "$lng_pve_configuration_text" 6 70 0
    return 0
  }

  whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_configuration" "$lng_nas_ask" ${r} ${c}
  yesno=$?
  if [[ $yesno == 0 ]]; then
    function pingNAS() {
      varnasip=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_ip" "$lng_nas_ip_text" ${r} ${c} 3>&1 1>&2 2>&3)
      if ping -c 1 "$varnasip" > /dev/null 2>&1; then
        varnasexists=y
        {
          for ((i = 98 ; i <= 100 ; i+=1)); do
            sleep 0.5
            echo $i
          done
        } | whiptail --gauge "$lng_nas_ip_check" 6 70 50
      else
        {
          for ((i = 98 ; i <= 100 ; i+=1)); do
            sleep 0.5
            echo $i
          done
        } | whiptail --gauge "$lng_nas_ip_check" 6 70 22
        whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_ip" "$lng_nas_ip_error" ${r} ${c}
        pingNAS
      fi
    }
    pingNAS
    whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_manufacturer" "$lng_nas_manufacturer_text" ${r} ${c}
    yesno=$?
    if [[ $yesno == 1 ]]; then
      varsynologynas=y
    else
      varsynologynas=n
    fi
    whiptail --yesno --yes-button "$lng_yes" --no-button "$lng_no" --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_folder_config" "$lng_nas_folder_config_text \"$varrobotname\" $lng_nas_folder_config_text1 \"$varrobotname\" $lng_nas_folder_config_text2" ${r} ${c}
    yesno=$?
    if [[ $yesno == 1 ]]; then
      whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_folder_config" "$lng_nas_folder_error" ${r} ${c}
      exit
    fi
  else
    varnasexists=n
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_nas_configuration" --title "$lng_nas_configuration" "$lng_nas_error" ${r} ${c}
  fi
  # Executes the Storage configuration
  configStorage
  echo "downloadPath=\"$downloadPath\"" >> $configFile
  echo "varnasip=\"$varnasip\"" >> $configFile
  echo "varnasexists=\"$varnasexists\"" >> $configFile
  echo "varsynologynas=\"$varsynologynas\"" >> $configFile
  return 0
}

function firewallConfig() {
  mkdir -p /etc/pve/firewall
  mkdir -p /etc/pve/nodes/$hostname
  clusterfileFW="/etc/pve/firewall/cluster.fw"
  hostfileFW="/etc/pve/nodes/$hostname/host.fw"

  # Firewall auf Clusterebene
  echo -e "[OPTIONS]\n\nenable: 1\n\n[IPSET network] # Heimnetzwerk\n$networkIP.0/$cidr\n\n[IPSET pnetwork] # alle privaten Netzwerke, wichtig für VPN\n10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16\n\n[RULES]\n\nGROUP proxmox\n\n[group proxmox]\n\nIN SSH(ACCEPT) -source +network -log nolog\nIN ACCEPT -source +network -p tcp -dport 8006 -log nolog\n\n" > $clusterfileFW
  
  # Firewall auf Hostebene
  echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP proxmox\n\n" > $hostfileFW
  echo "clusterfileFW=\"$clusterfileFW\"" >> $configFile
  echo "hostfileFW=\"$hostfileFW\"" >> $configFile
  return 0
}

function sqlSecure () {
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
}

function lxcConfig() {
  wget -qO /root/lxc.conf $rawGitHubURL/config/lxc.conf
  source /root/lxc.conf
  whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net - $lng_lxc_configuration" --title "$lng_lxc_configuration" "$lng_lxc_configuration_text" ${r} ${c} 10 "${lxc[@]}" 2>/root/lxcchoice
  sed -i 's#\"##g' /root/lxcchoice
  lxcchoice=$(cat /root/lxcchoice)
  whiptail --yesno --backtitle "© 2021 - SmartHome-IoT.net - $lng_lxc_configuration" --title "$lng_end_info" "$lng_end_info_text" ${r} ${c}
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_finish" --title "$lng_finish" "$lng_finish_text" ${r} ${c}
    return
  else
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - $lng_abort" --title "$lng_abort" "$lng_abort_text" ${r} ${c}
    exit
  fi
  echo "lxcchoice=\"$lxcchoice\"" >> $configFile
  return 0
}

function lxcMountNAS() {
  pct exec $1 -- bash -ci "mkdir -p /media"
  pct exec $1 -- bash -ci "mkdir -p /mnt/backup"
  pct exec $1 -- bash -ci "echo ""//$varnasip/media  /media  cifs credentials=/home/.smbmedia,uid=1000,gid=1000 0 0"" >> /etc/fstab"
  pct exec $1 -- bash -ci "echo ""//$varnasip/backups  /mnt/backup  cifs credentials=/home/.smbbackup,uid=1000,gid=1000 0 0"" >> /etc/fstab"
  pct exec $1 -- bash -ci "echo -e ""username=$varrobotname\npassword=$varrobotpw"" > /home/.smbmedia"
  pct exec $1 -- bash -ci "echo -e ""username=$varrobotname\npassword=$varrobotpw"" > /home/.smbbackup"
  pct exec $1 -- bash -ci "mount -a"
  nasFolder=$'\n\nNAS Verzeichnisse\nMedienverzeichnis: /media\nBackupverzeichnis: /mnt/backup'
}

function lxcSetup() {
  # Create Rootpassword for Container
  ctRootpw=$(createPassword 12)

  # Generates an ID and an IP address for the container to be created
  function createIDIP() {
    if [ $(pct list | grep -c 100) -eq 0 ]; then
      nextCTID=100
      lastCTIP=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f4)
      nextCTIP=$networkIP.$(( "$lastCTIP" + 5 ))
    else
      lastCTID=$(pct list | tail -n1 | awk '{print $1}')
      nextCTID=$(( "$lastCTID" + 1 ))
      lastCTIP=$(lxc-info "$lastCTID" -iH | grep "$networkIP" | cut -d. -f4)
      nextCTIP=$networkIP.$(( "$lastCTIP" + 1 ))
    fi
  }

  # Loads the container template from the Internet if not available and saves it for further use
  function downloadTemplate() {
    pveam update > /dev/null 2>&1
    if [[ $1 == "ubuntu" ]]; then
      ctTemplate=$(pveam available | grep $osUbuntu | awk '{print $2}')
      if [ $(pveam list "$downloadPath" | grep -c "$1") -eq 0 ]; then
        pveam download "$downloadPath" "$ctTemplate" > /dev/null 2>&1
      fi
      ctOstype="ubuntu"
    elif [[ $1 == "ubuntu18" ]]; then
      ctTemplate=$(pveam available | grep $osUbuntu18 | awk '{print $2}')
      if [ $(pveam list "$downloadPath" | grep -c "$1") -eq 0 ]; then
        pveam download $downloadPath "$ctTemplate" > /dev/null 2>&1
      fi
      ctOstype="ubuntu"
    elif [[ $1 == "debian" ]]; then
      ctTemplate=$(pveam available | grep $osDebian | awk '{print $2}')
      if [ $(pveam list "$downloadPath" | grep -c "$1") -eq 0 ]; then
        pveam download "$downloadPath" "$ctTemplate" > /dev/null 2>&1
      fi
      ctOstype="debian"
    elif [[ $1 == "debian9" ]]; then
      ctTemplate=$(pveam available | grep $osDebian9 | awk '{print $2}')
      if [ $(pveam list "$downloadPath" | grep -c "$1") -eq 0 ]; then
        pveam download "$downloadPath" "$ctTemplate" > /dev/null 2>&1
      fi
      ctOstype="debian"
    fi
  }

  # $1=ctTemplate (ubuntu/debian/turnkey-openvpn) - $2=hostname - $3=hdd size - $4=cpu cores - $5=RAM Swap/2 - $6=unprivileged 0/1 - $7=features (keyctl=1,nesting=1,mount=cifs)
  echo -e "XXX\n0\n$lng_lxc_setup_text_idip\nXXX"
  createIDIP
  sleep 0.5
  echo -e "XXX\n17\n$lng_lxc_setup_text_template_download\nXXX"
  downloadTemplate $1
  sleep 0.5
  echo -e "XXX\n28\n$lng_lxc_setup_text_container_install\nXXX"
  if [[ $downloadPath == "local" ]]; then rootfs="local-lvm"; else rootfs=$downloadPath; fi
  if [[ $7 == "" ]]; then
    pct create $nextCTID \
      $downloadPath:vztmpl/$ctTemplate \
      --ostype $ctOstype \
      --hostname "$2" \
      --password "$ctRootpw" \
      --rootfs $rootfs:$3 \
      --cores $4 \
      --memory $5 \
      --swap $(( $5 / 2 )) \
      --net0 bridge=vmbr0,name=eth0,ip="$nextCTIP"/$cidr,gw="$gatewayIP",ip6=dhcp,firewall=1 \
      --onboot 1 \
      --force 1 \
      --unprivileged $6 \
      --start 1 > /dev/null 2>&1
  else
    pct create $nextCTID \
      $downloadPath:vztmpl/$ctTemplate \
      --ostype $ctOstype \
      --hostname "$2" \
      --password "$ctRootpw" \
      --rootfs $rootfs:$3 \
      --cores $4 \
      --memory $5 \
      --swap $(( $5 / 2 )) \
      --net0 bridge=vmbr0,name=eth0,ip="$nextCTIP"/$cidr,gw="$gatewayIP",ip6=dhcp,firewall=1 \
      --onboot 1 \
      --force 1 \
      --unprivileged $6 \
      --start 1 \
      --features "$7" > /dev/null 2>&1
  fi
  sleep 0.5
  echo -e "XXX\n35\n$lng_lxc_setup_text_container_update\nXXX"
  if [[ $ctOStype == "debian" ]]; then
    pct exec $nextCTID -- bash -c "sed -i 's+#PermitRootLogin prohibit-password+PermitRootLogin yes+g'  /etc/locale.gen"
    pct exec $nextCTID -- bash -c "/etc/ssh/sshd_config > /dev/null 2>&1"
    pct exec $nextCTID -- bash -c "sed -i 's+# en_US.UTF-8 UTF-8+en_US.UTF-8 UTF-8+g'  /etc/locale.gen" # get en_US Language Support for the shell
    pct exec $nextCTID -- bash -c "localedef -i en_US -f UTF-8 en_US.UTF-8"
  fi
  pct exec $nextCTID -- bash -c "locale-gen en_US.UTF-8 > /dev/null 2>&1" # get en_US Language Support for the shell
  pct exec $nextCTID -- bash -c "export LANGUAGE=en_US.UTF-8"
  pct exec $nextCTID -- bash -c "export LANG=en_US.UTF-8"
  pct exec $nextCTID -- bash -c "export LC_ALL=en_US.UTF-8"
  pct exec $nextCTID -- bash -c "locale-gen en_US.UTF-8 > /dev/null 2>&1" # must do it for 2nd Time to set it right
  pct exec $nextCTID -- bash -c "apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1"
  echo -e "XXX\n42\n$lng_lxc_setup_text_software_install\nXXX"
  for package in $ctStandardsoftware; do
    pct exec $nextCTID -- bash -c "apt-get install -y $package > /dev/null 2>&1"
  done
  #pct exec $nextCTID -- bash -c "apt-get dist-upgrade -y > /dev/null 2>&1"
  echo -e "XXX\n51\n$lng_lxc_setup_text_finish\nXXX"
  pct shutdown $nextCTID --timeout 5
  sleep 10
  return $nextCTID
}

#if [ ! -f $configFile ]; then

clear
selectLanguage
startupInfo
pveConfig
networkConfig
emailConfig
nasConfig
firewallConfig
lxcConfig
lxcSetup

# Start creating the selected containers
for lxc in $lxcchoice; do
  ctName=$lxc
  if [ $(pct list | grep -c $ctName) -eq 0 ]; then
    wget -qO /root/inst_$ctName.sh $rawGitHubURL/container/$ctName/install.sh
    source /root/inst_$ctName.sh
  fi
done

# Cleanup
clear
rm *
