#!/bin/bash

debug=true

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
  repoUrlLXC="https://raw.githubusercontent.com/$repoUserLXC/$repoNameLXC/$repoVersionLXC"
else
  repoUserLXC=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "${lng_wrd_container} ${lng_wrd_repository}" "\n${lng_ask_github_username}" 10 80 3>&1 1>&2 2>&3)
  repoNameLXC=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "${lng_wrd_container} ${lng_wrd_repository}" "\n${lng_ask_github_repository}" 10 80 3>&1 1>&2 2>&3)
  repoVersionLXC=$(curl --silent "https://api.github.com/repos/$repoUserLXC/$repoNameLXC/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  repoUrlLXC="https://raw.githubusercontent.com/$repoUserLXC/$repoNameLXC/$repoVersionLXC"
fi

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

function createContainer() {
# Generates ID and IP-Address for the container to be created if is not the first
  if [ $(pct list | grep -cw 100) -eq 1 ]; then
    ctIDLast=$(pct list | tail -n1 | awk '{print $1}')
    ctID=$(( $ctIDLast +1 ))
    ctIP=$(( $(lxc-info $ctIDLast -iH | cut -d. -f4) +1 ))
  fi

# Get rootfs
  if [[ $ctTemplateDisk == "local" ]]; then
    rootfs="local-lvm"
  else
    rootfs=$ctTemplateDisk
  fi

# Create Container from Template File download Template OS if not exist
  lxcTemplateName="$(pveam available | grep "$template" | awk '{print $2}')"
  
  if [[ $template == "osDevuan" ]]; then
    osType="unmanaged"
  else
    osType=$(pveam available | grep "$template" | awk '{print $2}' | cut -d- -f1)
  fi

  echo ""
  echo ""
  echo ""
  echo $osType
  echo ""
  echo ""
  echo ""
  
  if [ $(pveam list "$ctTemplateDisk" | grep -c "$template") -eq 0 ]; then
    pveam download $ctTemplateDisk $lxcTemplateName > /dev/null 2>&1
  fi

  pctCreateCommand="$ctTemplateDisk:vztmpl/"$lxcTemplateName" \
                    --ostype "$osType" \
                    --hostname \"$hostname\" \
                    --password \"$ctRootPW\" \
                    --rootfs $rootfs:$hddsize \
                    --cores $cpucores \
                    --memory $memory \
                    --swap $swap \
                    --net0 name=eth0,bridge=vmbr0,ip=$networkIP.$ctIP/$cidr,gw=\"$gatewayIP\",ip6=dhcp,firewall=1 \
                    --onboot 1 \
                    --force 1 \
                    --unprivileged $unprivileged \
                    --start 0"
  if [ $(pveam available | grep "${template}" | awk '{print $2}' | grep -c amd64) -eq 1 ]; then pctCreateCommand="$pctCreateCommand --arch amd64"; fi
  if [ $(pveam available | grep "${template}" | awk '{print $2}' | grep -c i386) -eq 1 ]; then pctCreateCommand="$pctCreateCommand --arch i386"; fi
  if [[ -n "$features" ]]; then pctCreateCommand="$pctCreateCommand --features \"$features\""; fi
  pctCreateCommand="$( echo $pctCreateCommand | sed -e 's#                     # #g')"

  echo "pct create $ctID $pctCreateCommand"

  pct create $ctID $pctCreateCommand > /dev/null 2>&1 && sleep 5
}

function configContainer() {
# Load container language file if not exist load english language
  if curl --output /dev/null --silent --head --fail "$repoUrlLXC/$hostname/lang/$var_language.lang"; then
    source <(curl -sSL $repoUrlLXC/$hostname/lang/$var_language.lang)
  else
    source <(curl -sSL $repoUrlLXC/$hostname/lang/en.lang)
  fi

# Load the function.template File fromRepository if fncneeded
  if $fncneeded; then
    source <(curl -sSL $repoUrlLXC/$hostname/functions.template)
  fi

# Ask for SMTP-Password if SMTP is needed
  if $smtpneeded; then
    if [ -z "$var_mailpassword" ]; then
      var_mailpassword=$(whiptail --passwordbox --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_cancel} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_mailconfiguration}" --title "${lng_wrd_mailserver}" "\n${lng_ask_mail_server_password}" 10 80 3>&1 1>&2 2>&3)
      exitstatus=$?
      if [ $exitstatus = 1 ]; then
        exit
      fi
    fi
  fi

# Changes the App Armor profile for the container
  if [ -z "$apparmorProfile" ]; then
    sed -i 's#swap: '"$swap"'#swap: '"$swap"'\nlxc.apparmor.profile: '"$apparmorProfile"'#' >> /etc/pve/lxc/$ctID.conf
  fi

# Mounted the DVB-TV-Card and/or VGA-Card to container if exist and is needed
  if [ $(ls -la /dev/dvb/ | grep -c adapter0) -eq 1 ] && $dvbneeded; then
    echo "lxc.cgroup.devices.allow: c $(ls -la /dev/dvb/adapter0 | grep video | head -n1 | awk '{print $5}' | cut -d, -f1):* rwm" >> /etc/pve/lxc/$ctID.conf
    echo "lxc.mount.entry: /dev/dvb dev/dvb none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
  fi
  if [ $(ls -la /dev/dri/card0 | grep -c video) -eq 1 ] && $vganeeded; then
    echo "lxc.cgroup.devices.allow: c $(ls -la /dev/dri | grep video | head -n1 | awk '{print $5}' | cut -d, -f1):* rwm" >> /etc/pve/lxc/$ctID.conf
    echo "lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
    echo "lxc.mount.entry: /dev/dri/render$(ls -la /dev/dri | grep render | head -n1 | awk '{print $10}' | cut -d'r' -f3) dev/dri/render$(ls -la /dev/dri | grep render | head -n1 | awk '{print $10}' | cut -d'r' -f3) none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
  fi

# Insert created Container in Backup Pool
  pvesh set /pools/BackupPool -vms "$ctID"

# Start Container
  pct start "$ctID"

# Disable SSH client option SendEnv LC_* because errors occur during automatic processing
  pct exec $ctID -- bash -ci "sed -i 's+    SendEnv LANG LC_*+#   SendEnv LANG LC_*+g' /etc/ssh/ssh_config"

# Mounted the NAS to container if exist and is set in Container Configuration Template
  if $nasConfiguration && $nasneeded; then
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
    pct exec $ctID -- bash -ci "sed -i 's#map to guest = bad user#map to guest = never#' /etc/samba/smb.conf"
    pct exec $ctID -- bash -ci "chown -R smb: /root/sambashare"
    pct exec $ctID -- bash -ci "systemctl restart smbd.service"
  fi

# Update/Upgrade Container
  pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1"

# Install Container Standardsoftware
  pct exec $ctID -- bash -ci "apt-get install -y curl wget software-properties-common apt-transport-https lsb-release gnupg2 net-tools > /dev/null 2>&1"

# Commands that are executed in the container
  if [ -n "$lxcCommands" ]; then
    IFS=$'\n'
    for command in $lxcCommands; do
      pct exec $ctID -- bash -ci "$command"
    done
    unset IFS
  fi

# Commands to be executes in the Host (Proxmox) shell after complete Container creation (call functions)
  if [ -n "$pveCommands" ]; then
    IFS=$'\n'
    for command in $pveCommands; do
      $command
    done
    unset IFS
  fi

# Cleanup Container History
  pct exec ${ctID} -- bash -ci "cat /dev/null > ~/.bash_history && history -c && history -w"
}

for hostname in $var_lxcchoice; do
  if [ $(pct list | grep -cw "$hostname") -eq 0 ]; then
    ctRootPW="$(generatePassword 12)"
    source <(curl -sSL $repoUrlLXC/$hostname/install.template)
    createContainer
    configContainer
  else
    NEWT_COLORS='
          window=black,red
          border=white,red
          textbox=white,red
          button=black,yellow
        ' \
    whiptail --yesno --yes-button " ${lng_wrd_rename} " --no-button " ${lng_wrd_delete} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "$hostname" "\n${lng_txt_lxc_error}" 20 80
    yesno=$?
    if [ $yesno -eq 0 ]; then
      pct set $(pct list | grep -w $hostname | awk '{print $1}') --Hostname $(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "${lng_wrd_container}" "\n${lng_ask_lxc_rename}" 20 80 10 "${hostname}" 3>&1 1>&2 2>&3)
      ctRootPW="$(generatePassword 12)"
      source <(curl -sSL $repoUrlLXC/$hostname/install.template)
      createContainer
      configContainer
    else
      NEWT_COLORS='
            window=black,red
            border=white,red
            textbox=white,red
            button=black,yellow
          ' \
      whiptail --yesno --yes-button " ${lng_wrd_yes} " --no-button " ${lng_wrd_no} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "$hostname" "\n${lng_ask_lxc_realy_delete}" 20 80
      yesno=$?
      if [ $yesno -eq 0 ]; then
        pct destroy $(pct list | grep -w $hostname | awk '{print $1}') --destroy-unreferenced-disks --force 1 --purge 1
        ctRootPW="$(generatePassword 12)"
        source <(curl -sSL $repoUrlLXC/$hostname/install.template)
        createContainer
        configContainer
      else
        exit
      fi
    fi
  fi
done


