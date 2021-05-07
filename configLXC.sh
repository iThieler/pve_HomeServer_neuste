#!/bin/bash

##################### Operating systems ###################

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

#################### Required software ####################

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

configURL="https://raw.githubusercontent.com/shiot/pve_HomeServer/master"
rawSHIOTRepo="https://raw.githubusercontent.com/shiot/lxc_HomeServer/master"
configFile="/root/.cfg_shiot"
recoverConfig=false

# check if Proxmox is configured
if [ -f /root/.cfg_shiot ]; then
  source $configFile
  source <(curl -sSL ${configURL}/lang/${var_language}.lang)
else
  curl -sSL https://pve.config.shiot.de | bash
fi

# Load Container Installation Files from Repository
IFS=$'\n'
whiptail --yesno --yes-button " ${lng_btn_standard} " --no-button " ${lng_btn_other} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" "\n${lng_ask_diferent_repository}" ${r} ${c}
yesno=$?
if [ $yesno -eq 0 ]; then
  lxcConfigURL="${rawSHIOTRepo}"
else
  lxcConfigURL=$(whiptail --inputbox --ok-button " OK " --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "${lng_wrd_container} ${lng_wrd_repository}" "\n${lng_ask_url_repository}" ${ri} ${c} https://raw.githubusercontent.com/ 3>&1 1>&2 2>&3)
fi
unset IFS

for lxcChoice in $var_lxcchoice; do
  hostname=$( echo $lxcChoice | sed -e 's+\"++g' )
  # Load container language file if not exist load english language
  if curl --output /dev/null --silent --head --fail "$lxcConfigURL/$lxcChoice/lang/$var_language.lang"; then
    source <(curl -sSL ${lxcConfigURL}/$lxcChoice/lang/$var_language.lang)
    echo "containerLanguage"
  else
    source <(curl -sSL ${lxcConfigURL}/$lxcChoice/lang/en.lang)
    echo "containerLanguage EN"
  fi
  source <(curl -sSL ${lxcConfigURL}/$lxcChoice/install.template)
  echo "install.template"
done

# Container Variables
ctID=100
ctIP=$networkIP.$(( $(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f4) + 5 ))
ctTemplateDisk="local"
ctIDall=$(pct list | tail -n +2 | awk '{print $1}')

######################## Functions ########################

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

function generateIDIP() {
# Generates ID and IP-Address for the container to be created
  if [ $(pct list | grep -c 100) -eq 1 ]; then
    ctID=$(( $(pct list | tail -n1 | awk '{print $1}') + 1 ))
    ctIP=$networkIP.$(( $(lxc-info $(pct list | tail -n1 | awk '{print $1}') -iH | grep "$networkIP" | cut -d. -f4) + 1 ))
  fi
}

function downloadTemplate() {
# Loads the container template from the Internet if not available and saves it for further use
  if [[ $template == "osDevuan" ]]; then
    OSstype="unmanaged"
  else
    OSstype=$(pveam available | grep "${template}" | awk '{print $2}' | cut -d- -f1)
  fi
  if [ $(pveam list "$ctTemplateDisk" | grep -c "${template}") -eq 0 ]; then
    pveam download $ctTemplateDisk $(pveam available | grep "${template}" | awk '{print $2}') > /dev/null 2>&1
  fi
}

function createContainer() {
# Create Container from Template
  if [[ $ctTemplateDisk == "local" ]]; then rootfs="local-lvm"; else rootfs=$ctTemplateDisk; fi
  if [[ $features == "" ]]; then
    pct create $ctID \
      $ctTemplateDisk:vztmpl/$(pveam available | grep "${template}" | awk '{print $2}') \
      --ostype $OSstype \
      --hostname "$hostname" \
      --password "$ctRootpw" \
      --rootfs $rootfs:$hddsize \
      --cores $cpucores \
      --memory $memory \
      --swap $swap \
      --net0 name=eth0,bridge=vmbr0,ip="$ctIP"/$cidr,gw="$gatewayIP",ip6=manual,firewall=1 \
      --onboot 1 \
      --force 1 \
      --unprivileged $unprivileged \
      --start 1 > /dev/null 2>&1
  else
    pct create $ctID \
      $ctTemplateDisk:vztmpl/$(pveam available | grep "${template}" | awk '{print $2}') \
      --ostype $OSstype \
      --hostname "$hostname" \
      --password "$ctRootpw" \
      --rootfs $rootfs:$hddsize \
      --cores $cpucores \
      --memory $memory \
      --swap $swap \
      --net0 name=eth0,bridge=vmbr0,ip="$ctIP"/$cidr,gw="$gatewayIP",ip6=manual,firewall=1 \
      --onboot 1 \
      --force 1 \
      --unprivileged $unprivileged \
      --start 1 \
      --features "$features" > /dev/null 2>&1
  fi
  sleep 5
  pct exec $ctID -- bash -ci "sed -i 's+    SendEnv LANG LC_*+#   SendEnv LANG LC_*+g' /etc/ssh/ssh_config"    # Disable SSH client option SendEnv LC_* because errors occur during automatic processing
}

function createContainerDescription() {
# Create Container description, you can find it on Proxmox WebGUI
  lxcConfigFile="/etc/pve/lxc/$ctID.conf"
  lxcConfigOld=$(cat $lxcConfigFile)
  if [[ $description == "" ]]; then
    echo -e "#>> Shell <<\n#$lng_wrd_user:   root\n#$lng_wrd_password:   $ctRootpw" > $lxcConfigFile
  else
    echo -e "#${description}\n#\n#>> Shell <<\n#$lng_wrd_user:   root\n#$lng_wrd_password:   $ctRootpw" > $lxcConfigFile
  fi
  if $webgui; then
    for ((i=0;i<=${#webguiPort[@]};i++)); do
      if [[ ${webguiPort[i]} == "" ]]; then webguiAdress="${webguiProt[i]}://$ctIP"; else webguiAdress="${webguiProt[i]}://${ctIP}:${webguiPort[i]}"; fi
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
    echo -e "#\n#>> Samba (smb) <<\n#Windows-$lng_wrd_sharedfolder:   \\\\\\$ctIP\n#Mac-$lng_wrd_sharedfolder:       smb://$ctIP\n#Linux-$lng_wrd_sharedfolder:     smb://$ctIP" >> $lxcConfigFile
    echo -e "$smbuserdesc" >> $lxcConfigFile
  fi
  echo -e "$lxcConfigOld" >> $lxcConfigFile
}

function createContainerFirewallRules() {
# Create Firewall Group and Rules for Container
  echo -e "\n[group $(echo $hostname|tr "[:upper:]" "[:lower:]")]" >> $clusterfileFW    # This Line will create the Firewall Goup Containername - don't change it
  if [ -n "$inst_samba" ]; then
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
  echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $hostname|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw    # Allow generated Firewallgroup, don't change it
}

function mountNASToContainer() {
# Mounted the NAS to container if exist and is set in Container Configuration Template
  if [ -n "$var_nasip" ] && $nasneeded; then
    pct exec $ctID -- bash -ci "mkdir -p /media"
    pct exec $ctID -- bash -ci "mkdir -p /mnt/backup"
    pct exec $ctID -- bash -ci "echo \"//$var_nasip/media  /media  cifs  credentials=/home/.smbmedia,uid=1000,gid=1000  0  0\" >> /etc/fstab"
    pct exec $ctID -- bash -ci "echo \"//$var_nasip/backups  /mnt/backup  cifs  credentials=/home/.smbbackup,uid=1000,gid=1000  0  0\" >> /etc/fstab"
    pct exec $ctID -- bash -ci "echo -e \"username=$var_robotname\npassword=$var_robotpw\" > /home/.smbmedia"
    pct exec $ctID -- bash -ci "echo -e \"username=$var_robotname\npassword=$var_robotpw\" > /home/.smbbackup"
    pct exec $ctID -- bash -ci "mount -a"
  fi
}

function mountHardwareToContainer() {
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
}

function installSamba() {
# Install Samba to Container if inst_samba Variable is true
  if [ -z "$inst_samba" ]; then
    pct exec $ctID -- bash -ci "apt-get install -y samba samba-common-bin > /dev/null 2>&1"
    for user in $sambaUser; do
      smbpasswd=$(generatePassword 8)
      pct exec $ctID -- bash -ci "adduser --no-create-home --disabled-login --shell /bin/false $user"
      pct exec $ctID -- bash -ci "( echo \"$smbpasswd\"; sleep 1; echo \"$smbpasswd\" ) | sudo smbpasswd -s -a $user"
      pct exec $ctID -- bash -ci "mkdir -p /root/sambashare/$user"
      pct exec $ctID -- bash -ci "echo -e \"\n[$user]\ncomment = Sambashare\npath = /root/sambashare/$user\nwrite list = $user\nvalid users = $user\nforce user = smb\" >> /etc/samba/smb.conf"
      if [[ ${smbuserdesc} == "" ]]; then
        smbuserdesc="#$lng_wrd_user:   $user\n#$lng_wrd_password:   $smbpasswd"
      else
        smbuserdesc="${smbuserdesc}\n#$lng_wrd_user:   $user\n#$lng_wrd_password:   $smbpasswd"
      fi
    done
    pct exec $ctID -- bash -ci "sed -i 's#map to guest = bad user#map to guest = never#' /etc/samba/smb.conf"
    pct exec $ctID -- bash -ci "chown -R smb: /root/sambashare"
    pct exec $ctID -- bash -ci "systemctl restart smbd.service"
  fi
}

if $fncneeded; then
# Load the function.template File fromRepository if fncneeded
  source <(curl -sSL ${lxcConfigURL}/$hostname/functions.template)
  echo "functions.template"
fi

function createLXC() {
# Function creates the LXC container
  ctRootpw=$(generatePassword 12)   # Create Rootpassword for Container
  # check if HDD for Container Templates has been changed
  if [ $(pct list | grep -cw "${hostname}") -eq 0 ]; then
    {
      echo -e "XXX\n2\n${lng_txt_lxc_gen_idip}\nXXX"
      generateIDIP

      #echo -e "XXX\n9\n${lng_txt_lxc_template_download}\nXXX"
      echo "9"
      downloadTemplate

      #echo -e "XXX\n19\n${lng_txt_lxc_added}\nXXX"
      echo "19"
      createContainer

      echo -e "XXX\n24\n${lng_txt_lxc_mount_nas}\nXXX"
      mountNASToContainer

      # Changes the App Armor profile for the container
      if [ -z $apparmorProfile ]; then sed -i 's#swap: '"$swap"'#swap: '"$swap"'\nlxc.apparmor.profile: '"$apparmorProfile"'#' >> /etc/pve/lxc/$ctID.conf; fi

      echo -e "XXX\n31\n${lng_txt_lxc_bind_hardware}\nXXX"
      mountHardwareToContainer

      # Restart container if App Armor Profile is changed, DVB-TV-Card or VGA-Card is created in LXC
      if [[ $apparmorProfile != "" ]] || $dvbneeded || $vganeeded; then
        echo -e "XXX\n39\n${lng_wrd_restart}\nXXX"
        pct reboot ${ctID}
        sleep 15
      fi

      # Update/Upgrade Container
      echo -e "XXX\n41\n${lng_txt_lxc_update}\nXXX"
      pct exec ${ctID} -- bash -ci "apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1"
      
      # Install Container Standardsoftware
      echo -e "XXX\n48\n${lng_txt_lxc_software_install}\nXXX"
      for ct_package in $lxc_Standardsoftware; do
        pct exec ${ctID} -- bash -ci "apt-get install -y $ct_package > /dev/null 2>&1"
      done

      echo -e "XXX\n59\n${lng_txt_lxc_software_install}\nXXX"
      installSamba

      # Commands that are executed in the container
      echo -e "XXX\n68\n${lng_txt_lxc_software_install}\nXXX"
      if [ -n "$lxcCommands" ]; then
        IFS=$'\n'
        for lxccommand in $lxcCommands; do
          pct exec ${ctID} -- bash -ci "$lxccommand"
        done
        unset IFS
      fi
      
      # Commands to be executes in the Host (Proxmox) shell after complete Container creation (call functions)
      if [ -n "$pveCommands" ]; then
        echo -e "XXX\n82\n${lng_txt_lxc_create_finish}\nXXX"
        IFS=$'\n'
        for command in $pveCommands; do
          $command
        done
        unset IFS
      fi
      
      echo -e "XXX\n94\n${lng_txt_lxc_create_description}\nXXX"
      createContainerDescription
      pct reboot ${ctID} --timeout 5
      sleep 15

      echo -e "XXX\n99\n${lng_txt_lxc_create_firewall}\nXXX"
      createContainerFirewallRules
      
      # Insert createt Container in Backup Pool
      pvesh set /pools/BackupPool -vms "${ctID}"

    } | whiptail --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "$hostname" --gauge "${lng_wrd_preparation}" ${ri} ${c} 0
  else
    NEWT_COLORS='
          window=black,red
          border=white,red
          textbox=white,red
          button=black,yellow
        ' \
    whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "$hostname" "\n${lng_txt_lxc_error}" ${r} ${c}
  fi
  pct exec $ctID -- bash -ci "cat /dev/null > ~/.bash_history && history -c && history -w"
}

####################### start Script ######################

pveam update > /dev/null 2>&1

if [ -z "$var_robotpw" ]; then
  var_robotpw=$(whiptail --passwordbox --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_cancel} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_network_infrastructure}" --title "${lng_wrd_password}" "\n${lng_txt_netrobot_password}\n\n${lng_ask_netrobot_password}" ${ri} ${c} 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 1 ]; then
    exit
  fi
fi

if $smtpneeded; then
  if [ -z "$var_mailpassword" ]; then
    var_mailpassword=$(whiptail --passwordbox --ok-button " ${lng_btn_ok} " --cancel-button " ${lng_btn_cancel} " --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_mailconfiguration}" --title "${lng_wrd_mailserver}" "\n${lng_ask_mail_server_password}" ${ri} ${c} 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 1 ]; then
      exit
    fi
  fi
fi

if $nasConfiguration; then
  source <(curl -sSL ${lxcConfigURL}/nas.list)
else
  source <(curl -sSL ${lxcConfigURL}/nonas.list)
fi

var_lxcchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net - ${lng_wrd_container} ${lng_wrd_configuration}" --title "${lng_wrd_container}" "${lng_txt_lxc_choose_container}" ${r} ${c} 10 "${lxclist[@]}" 3>&1 1>&2 2>&3)
var_lxcchoice=$(echo $var_lxcchoice | sed -e 's#\"##g')

for hostname in $var_lxcchoice; do
  createLXC
done

exit
