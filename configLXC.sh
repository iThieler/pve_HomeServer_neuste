#!/bin/bash

# Operating systems
osAlpine3_11="alpine-3.11-default"       # Container Template for Alpine v3.11
osAlpine3_12="alpine-3.12-default"       # Container Template for Alpine v3.12
osArchlinux="archlinux-base"             # Container Template for archLinux
osCentos7="centos-7-default"             # Container Template for Centos v7
osCentos8="centos-8-default"             # Container Template for Centos v8
osDebian9="debian-9.0-standard"          # Container Template for Debian v9
osDebian10="debian-10-standard"          # Container Template for Debian v10
osDevuan3_0="devuan-3.0-standard"        # Container Template for Devuan v3.0
osFedora32="fedora-32-default"           # Container Template for Fedora v32
osFedora33="fedora-33-default"           # Container Template for Fedora v33
osGentoo="gentoo-current-default"        # Container Template for current Gentoo
osOpensuse15_2="opensuse-15.2-default"   # Container Template for openSUSE v15.2
osUbuntu18_04="ubuntu-18.04-standard"    # Container Template for Ubuntu v18.04
osUbuntu20_04="ubuntu-20.04-standard"    # Container Template for Ubuntu v20.04
osUbuntu20_10="ubuntu-20.10-standard"    # Container Template for Ubuntu v20.10

debug=true
echo "debug: $debug"

# check if Variable is valid URL
regexURL='^(https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'  # if [[ ! $URL =~ $regexURL ]]; then; fi

# Checks Proxmox is configured by SmartHome-IoT.net if not exit
configFile="/root/.cfg_shiot"
if [ ! -f $configFile ]; then
  exit
fi

# Set Repo URL's
if $debug; then
  repoVersionPVE="master"
else
  repoVersionPVE=$(curl --silent "https://api.github.com/repos/shiot/pve_HomeServer/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
fi

repoUrlPVE="https://raw.githubusercontent.com/shiot/pve_HomeServer/$repoVersionPVE"

# Load PVE Configuration Variables and update Template Dictionary
if [ -f "$configFile" ]; then
  source $configFile
  source <(curl -sSL $repoUrlPVE/lang/$var_language.lang)
  pveam update > /dev/null 2>&1
else
  exit
fi

whiptail --yesno --yes-button " ${lng_btn_standard} " --no-button " ${lng_btn_other} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" "\n${lng_ask_diferent_repository}" 20 80
yesno=$?
if [ $yesno -eq 0 ]; then
  repoUserLXC=shiot
  repoNameLXC=lxc_HomeServer
  if $debug; then
    repoVersionLXC="master"
  else
    repoVersionLXC=$(curl --silent "https://api.github.com/repos/$repoUserLXC/$repoNameLXC/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  fi
else
  repoUserLXC=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "${lng_wrd_container} ${lng_wrd_repository}" "\n${lng_ask_github_username}" 10 80 3>&1 1>&2 2>&3)
  repoNameLXC=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "${lng_wrd_container} ${lng_wrd_repository}" "\n${lng_ask_github_repository}" 10 80 3>&1 1>&2 2>&3)
  repoVersionLXC=$(curl --silent "https://api.github.com/repos/$repoUserLXC/$repoNameLXC/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
fi

# set Repo URL
export repoUrlLXC="https://raw.githubusercontent.com/$repoUserLXC/$repoNameLXC/$repoVersionLXC"

# Load Container Repository
source <(curl -sSL $repoUrlLXC/_template/install.template)    # Loads the template file so all variables are set
if $nasConfiguration; then
  source <(curl -sSL $repoUrlLXC/nas.list)
else
  source <(curl -sSL $repoUrlLXC/nonas.list)
fi

# Choose Container to create
var_lxcchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "${lng_wrd_container}" "\n${lng_txt_lxc_choose_container}" 20 80 10 "${lxclist[@]}" 3>&1 1>&2 2>&3)
var_lxcchoice="$(echo $var_lxcchoice | sed -e 's#\"##g')"

# Ask for Robotpassword if not set in config File
if [ -z "$var_robotpw" ]; then
  var_robotpw=$(whiptail --passwordbox --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_cancel} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_netrobot}" "\n${lng_ask_netrobot_password}" 10 80 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus -eq 1 ]; then
    exit
  fi
  # Set Variables used by this Script
  ctRootPW=""
  ctID="100"
  hostIP=$(echo $pveIP | cut -d. -f4)
  ctIP="$(( $hostIP + 5 ))"
fi

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

function makeSQLSecure () {
# Function configures SQL secure in LXC Containers
  SECURE_MYSQL=$(expect -c "
  set timeout 3
  spawn mysql_secure_installation
  expect \"Press y|Y for Yes, any other key for No:\"
  send \"n\r\"
  expect \"New password:\"
  send \"${ctRootPW}\r\"
  expect \"Re-enter new password:\"
  send \"${ctRootPW}\r\"
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

function createContainer() {
  {
  # Generates ID and IP-Address for the container to be created if is not the first
    echo 8
    if [ $(pct list | grep -cw 100) -eq 1 ]; then
      ctIDLast=$(pct list | tail -n1 | awk '{print $1}')
      ctIPLast=$(lxc-info $ctIDLast -iH | cut -d. -f4)
      ctID=$(( $ctIDLast +1 ))
      ctIP=$(( $ctIPLast +1 ))
    fi

  # Get rootfs
    echo 11
    if [[ $ctTemplateDisk == "local" ]]; then
      rootfs="local-lvm"
    else
      rootfs=$ctTemplateDisk
    fi

  # Create Container from Template File download Template OS if not exist
    echo 15
    lxcTemplateName="$(pveam available | grep "$template" | awk '{print $2}')"
    
    if [[ $template == "osDevuan" ]]; then
      osType="unmanaged"
    else
      osType=$(pveam available | grep "$template" | awk '{print $2}' | cut -d- -f1)
    fi
    
    if [ $(pveam list "$ctTemplateDisk" | grep -c "$template") -eq 0 ]; then
      pveam download $ctTemplateDisk $lxcTemplateName > /dev/null 2>&1
    fi

    pctCreateCommand="$ctTemplateDisk:vztmpl/$lxcTemplateName \
                      --ostype "$osType" \
                      --hostname $hostname_lxc \
                      --password \"$ctRootPW\" \
                      --rootfs $rootfs:$hddsize \
                      --cores $cpucores \
                      --memory $memory \
                      --swap $swap \
                      --net0 name=eth0,bridge=vmbr0,firewall=1,gw=$gatewayIP,ip=$networkIP.$ctIP/$cidr,ip6=dhcp \
                      --onboot 1 \
                      --force 1 \
                      --unprivileged $unprivileged \
                      --start 0"
    if [ -n "$features" ]; then pctCreateCommand="$pctCreateCommand --features $features"; fi
    pctCreateCommand="$( echo $pctCreateCommand | sed -e 's#                     # #g')"

    pct create $ctID $pctCreateCommand > /dev/null 2>&1
    sleep 10
  } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_wrd_container $lng_wrd_configuration" --title "$hostname_lxc" --gauge "$lng_txt_lxc_added" 10 80 0
}

function configContainer() {
  {
  # Load container language file if not exist load english language
    if curl --output /dev/null --silent --head --fail "$repoUrlLXC/$hostname_lxc/lang/$var_language.lang"; then
      source <(curl -sSL $repoUrlLXC/$hostname_lxc/lang/$var_language.lang)
    else
      source <(curl -sSL $repoUrlLXC/$hostname_lxc/lang/en.lang)
    fi

  # Load the function.template File fromRepository if fncneeded
    if $fncneeded; then
      source <(curl -sSL $repoUrlLXC/$hostname_lxc/functions.template)
    fi

  # Ask for SMTP-Password if SMTP is needed
    if $smtpneeded; then
      echo 22
      if [ -z "$var_mailpassword" ]; then
        var_mailpassword=$(whiptail --passwordbox --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_cancel} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_mailconfiguration}" --title "${lng_wrd_mailserver}" "\n${lng_ask_mail_server_password}" 10 80 3>&1 1>&2 2>&3)
        exitstatus=$?
        if [ $exitstatus = 1 ]; then
          exit
        fi
      fi
    fi

  # Changes the App Armor profile for the container
    if [ -n "$apparmorProfile" ]; then
      sed -i 's#swap: '"$swap"'#swap: '"$swap"'\nlxc.apparmor.profile: '"$apparmorProfile"'#' /etc/pve/lxc/$ctID.conf > /dev/null 2>&1
    fi

  # Mounted the DVB-TV-Card and/or VGA-Card to container if exist and is needed
    if [ $(ls -la /dev/dvb/ | grep -c adapter0) -eq 1 ] && $dvbneeded; then
      echo 25
      echo "lxc.cgroup.devices.allow: c $(ls -la /dev/dvb/adapter0 | grep video | head -n1 | awk '{print $5}' | cut -d, -f1):* rwm" >> /etc/pve/lxc/$ctID.conf
      echo "lxc.mount.entry: /dev/dvb dev/dvb none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
    fi
    if [ $(ls -la /dev/dri/card0 | grep -c video) -eq 1 ] && $vganeeded; then
      echo 29
      echo "lxc.cgroup.devices.allow: c $(ls -la /dev/dri | grep video | head -n1 | awk '{print $5}' | cut -d, -f1):* rwm" >> /etc/pve/lxc/$ctID.conf
      echo "lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
      echo "lxc.mount.entry: /dev/dri/render$(ls -la /dev/dri | grep render | head -n1 | awk '{print $10}' | cut -d'r' -f3) dev/dri/render$(ls -la /dev/dri | grep render | head -n1 | awk '{print $10}' | cut -d'r' -f3) none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
    fi

  # Insert created Container in Backup Pool
    echo 32
    pvesh set /pools/BackupPool -vms "$ctID"

  # Start Container
    pct start $ctID
    sleep 10

  # Disable SSH client option SendEnv LC_* because errors occur during automatic processing
    pct exec $ctID -- bash -ci "sed -i 's+    SendEnv LANG LC_*+#   SendEnv LANG LC_*+g' /etc/ssh/ssh_config > /dev/null 2>&1"

  # Mounted the NAS to container if exist and is set in Container Configuration Template
    if $nasConfiguration && $nasneeded; then
      echo 44
      pct exec $ctID -- bash -ci "mkdir -p /media"
      pct exec $ctID -- bash -ci "mkdir -p /mnt/backup"
      pct exec $ctID -- bash -ci "echo \"//$var_nasip/media  /media  cifs  credentials=/home/.smbmedia,uid=1000,gid=1000  0  0\" >> /etc/fstab"
      pct exec $ctID -- bash -ci "echo \"//$var_nasip/backups  /mnt/backup  cifs  credentials=/home/.smbbackup,uid=1000,gid=1000  0  0\" >> /etc/fstab"
      pct exec $ctID -- bash -ci "echo -e \"username=$var_robotname\npassword=$var_robotpw\" > /home/.smbmedia"
      pct exec $ctID -- bash -ci "echo -e \"username=$var_robotname\npassword=$var_robotpw\" > /home/.smbbackup"
      pct exec $ctID -- bash -ci "mount -a"
    fi

  # Install Samba to Container if inst_samba Variable is true
    if $inst_samba; then
      echo 53
      smbuserdesc=""
      pct exec $ctID -- bash -ci "apt-get install -y samba samba-common-bin > /dev/null 2>&1"
      for user in $sambaUser; do
        smbpasswd=$(generatePassword 8)
        pct exec $ctID -- bash -ci "adduser --no-create-home --disabled-login --shell /bin/false $user"
        pct exec $ctID -- bash -ci "( echo \"$smbpasswd\"; sleep 1; echo \"$smbpasswd\" ) | sudo smbpasswd -s -a $user"
        pct exec $ctID -- bash -ci "mkdir -p /root/sambashare/$user"
        pct exec $ctID -- bash -ci "echo -e \"\n[$user]\ncomment = Sambashare\npath = /root/sambashare/$user\nwrite list = $user\nvalid users = $user\nforce user = smb\" >> /etc/samba/smb.conf"
        if [ -z "$smbuserdesc" ]; then
          smbuserdesc="#$lng_wrd_user:   $user\n#$lng_wrd_password:   $smbpasswd"
        else
          smbuserdesc="${smbuserdesc}\n#$lng_wrd_user:   $user\n#$lng_wrd_password:   $smbpasswd"
        fi
      done
      pct exec $ctID -- bash -ci "sed -i 's#map to guest = bad user#map to guest = never#' /etc/samba/smb.conf > /dev/null 2>&1"
      pct exec $ctID -- bash -ci "chown -R smb: /root/sambashare"
      pct exec $ctID -- bash -ci "systemctl restart smbd.service"
    fi

  # Update/Upgrade Container
    echo 55
    pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1"

  # Install Container Standardsoftware
    echo 67
    pct exec $ctID -- bash -ci "apt-get install -y curl wget software-properties-common apt-transport-https lsb-release gnupg2 net-tools > /dev/null 2>&1"

  # Commands that are executed in the container
    if [ -n "$lxcCommands" ]; then
      echo 73
      IFS=$'\n'
      for command in $lxcCommands; do
        pct exec $ctID -- bash -ci "$command"
      done
      unset IFS
    fi

  # Commands to be executes in the Host (Proxmox) shell after complete Container creation (call functions)
    if [ -n "$pveCommands" ]; then
      echo 87
      IFS=$'\n'
      for command in $pveCommands; do
        $command
      done
      unset IFS
    fi

  # Create Container description, you can find it on Proxmox WebGUI
    echo 94
    lxcConfigFile="/etc/pve/lxc/$ctID.conf"
    lxcConfigOld=$(cat $lxcConfigFile)

    if [ -n "$description" ]; then
      echo -e "#>> Shell <<\n#$lng_wrd_user:   root\n#$lng_wrd_password:   $ctRootPW" > $lxcConfigFile
    else
      echo -e "#${description}\n#\n#>> Shell <<\n#$lng_wrd_user:   root\n#$lng_wrd_password:   $ctRootPW" > $lxcConfigFile
    fi

    if $webgui; then
      for ((i=0;i<=${#webguiPort[@]};i++)); do
        if [[ ${webguiPort[i]} == "" ]]; then webguiAdress="${webguiProt[i]}://$networkIP.$ctIP"; else webguiAdress="${webguiProt[i]}://$networkIP.$ctIP:${webguiPort[i]}"; fi
        if [[ ! ${webguiPath[i]} == "" ]]; then webguiAdress="${webguiAdress}${webguiPath[i]}"; fi
        if [[ ! ${webguiName[i]} == "" ]]; then
          if [ $i -lt 1 ]; then
            echo -e "#\n#>> ${webguiName[i]} <<\n#$lng_wrd_webadress:   $webguiAdress" >> $lxcConfigFile
          else
            echo -e "#>> ${webguiName[i]} <<\n#$lng_wrd_webadress:   $webguiAdress" >> $lxcConfigFile
          fi
        fi
        if [[ ! ${webguiUser[i]} == "" ]]; then echo -e "#$lng_wrd_user:   ${webguiUser[i]}" >> $lxcConfigFile; fi
        if [[ ! ${webguiPass[i]} == "" ]]; then echo -e "#$lng_wrd_password:   ${webguiPass[i]}" >> $lxcConfigFile; fi
      done
    fi

    if [ -n "$var_nasip" ] && $nasneeded; then
      echo -e "#\n#>> $lng_wrd_nas <<\n#$lng_wrd_mediafolder:   /media\n#$lng_wrd_backupfolder:   /mnt/backup" >> $lxcConfigFile
    fi

    if $inst_samba; then
      echo -e "#\n#>> Samba (smb) <<\n#Windows-$lng_wrd_sharedfolder:   \\\\\\$networkIP.$ctIP\n#Mac-$lng_wrd_sharedfolder:       smb://$networkIP.$ctIP\n#Linux-$lng_wrd_sharedfolder:     smb://$networkIP.$ctIP" >> $lxcConfigFile
      echo -e "$smbuserdesc" >> $lxcConfigFile
    fi
    echo -e "$lxcConfigOld" >> $lxcConfigFile

  # Create Firewall Group and Rules for Container
    echo 97
    clusterfileFW="/etc/pve/firewall/cluster.fw"
    echo -e "\n[group $(echo fwsg_$hostname_lxc | tr "[:upper:]" "[:lower:]")]" >> $clusterfileFW    # This Line will create the Firewall Goup Containername - don't change it

    if $inst_samba; then
      echo -e "IN ACCEPT -source +network -p tcp -dport 445 -log nolog # Samba (smb)" >> $clusterfileFW
      echo -e "IN ACCEPT -source +network -p tcp -dport 137 -log nolog # Samba (NetBios/Name resolution)" >> $clusterfileFW
      echo -e "IN ACCEPT -source +network -p udp -dport 137 -log nolog # Samba (NetBios/Name resolution)" >> $clusterfileFW
      echo -e "IN ACCEPT -source +network -p udp -dport 138 -log nolog # Samba (NetBios/Name resolution)" >> $clusterfileFW
      echo -e "IN ACCEPT -source +network -p tcp -dport 139 -log nolog # Samba (NetBios/Name resolution)" >> $clusterfileFW
    fi

    for ((i=0;i<=${#fwPort[@]};i++)); do
      if [[ ${fwNetw[i]} == "" ]]; then fwnw=""; else fwnw=" -source +${fwNetw[i]}"; fi
      if [[ ${fwDesc[i]} == "" ]]; then fw_desc=""; else fw_desc=" # ${fwDesc[i]}"; fi
      echo -e "IN ACCEPT$fwnw -p ${fwProt[i]} -dport ${fwPort[i]} -log nolog$fw_desc" >> $clusterfileFW
    done

    echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $hostname_lxc|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw    # Allow generated Firewallgroup, don't change it

  # Cleanup Container History an reboot
    echo 99
    pct exec $ctID -- bash -ci "cat /dev/null > ~/.bash_history && history -c && history -w"
    pct reboot $ctID --timeout 5
  } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - $lng_wrd_container $lng_wrd_configuration" --title "$hostname_lxc" --gauge "$lng_txt_lxc_config" 10 80 18
}

for choosedLXC in $var_lxcchoice; do
  export hostname_lxc=$choosedLXC
  if [ $(pct list | grep -cw "$hostname_lxc") -eq 0 ]; then
    ctRootPW="$(generatePassword 12)"
    source <(curl -sSL $repoUrlLXC/$hostname_lxc/install.template)
    createContainer
    configContainer
  else
    NEWT_COLORS='
          window=black,red
          border=white,red
          textbox=white,red
          button=black,yellow
        ' \
    whiptail --yesno --yes-button " ${lng_wrd_rename} " --no-button " ${lng_wrd_delete} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "$hostname_lxc" "\n${lng_txt_lxc_error}" 20 80
    yesno=$?
    # Rename existing Container with same Name
    if [ $yesno -eq 0 ]; then
      newName=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "${lng_wrd_container}" "\n${lng_ask_lxc_rename}\n\n${lng_txt_hostname_lxc}" 10 80 "${hostname_lxc}-old" 3>&1 1>&2 2>&3)
      # Check if $newName is a valid hostname_lxc containe only upper and lower case letters and/or digits if it is skip Container creation
      if [[ $newName =~ ^[A-Za-z0-9-]+$ ]] && [[ $newName != *[ÄäÖöÜüß]* ]]; then
        id=$(pct list | grep -w $hostname_lxc | awk '{print $1}')
        pct shutdown $id --timeout 5
        sleep 10
        pct set $id --hostname_lxc $newName > /dev/null 2>&1
        sleep 10
        pct start $id
        sleep 10
        ctRootPW="$(generatePassword 12)"
        source <(curl -sSL $repoUrlLXC/$hostname_lxc/install.template)
        createContainer
        configContainer
      fi
    else
      NEWT_COLORS='
            window=black,red
            border=white,red
            textbox=white,red
            button=black,yellow
          ' \
      whiptail --yesno --yes-button " ${lng_btn_yes} " --no-button " ${lng_btn_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "$hostname_lxc" "\n${lng_ask_lxc_realy_delete}" 10 80
      yesno=$?
      # Ask if Container realy want to delete existing Container,if not skip Container creation
      if [ $yesno -eq 0 ]; then
        pct destroy $(pct list | grep -w $hostname_lxc | awk '{print $1}') --destroy-unreferenced-disks --force 1 --purge 1 > /dev/null 2>&1
        ctRootPW="$(generatePassword 12)"
        source <(curl -sSL $repoUrlLXC/$hostname_lxc/install.template)
        createContainer
        configContainer
      fi
    fi
  fi
done

# Cleanup Shell History
cat /dev/null > ~/.bash_history && history -c && history -w

exit
