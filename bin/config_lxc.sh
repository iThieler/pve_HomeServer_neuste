#!/bin/bash

source "/root/pve_HomeServer/bin/variables.sh"
source "$script_path/bin/var_containerOS.sh"
source "$script_path/handler/global_functions.sh"
source "$script_path/language/$var_language.sh"
source "$shiot_configPath/$shiot_configFile"

ctID=$1
containername="$(pct list | grep $ctID | awk '{print $3}')"

# Load container language file if not exist load english language
if "$script_path/lxc/$containername/language/$var_language.sh"; then
  source "$script_path/lxc/$containername/language/$var_language.sh"
else
  source "$script_path/lxc/$containername/language/en.sh"
fi

# Load special functions for Container config
if "$script_path/lxc/$containername/functions.sh"; then
  source "$script_path/lxc/$containername/functions.sh"
fi

# Ask for SMTP-Password if SMTP is needed
if $smtpneeded; then
  if [ -z "$var_mailpassword" ]; then
    var_mailpassword=$(whiptail --passwordbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_5} " "\n${txt_0065}" 10 80 3>&1 1>&2 2>&3)
  fi
fi

# Changes the App Armor profile for the container
if [ -n "$apparmorProfile" ]; then
  sed -i 's#swap: '"$swap"'#swap: '"$swap"'\nlxc.apparmor.profile: '"$apparmorProfile"'#' /etc/pve/lxc/$ctID.conf > /dev/null 2>&1
fi

# Mounted the DVB-TV-Card to container if exist and is needed
if [ $(ls -la /dev/dvb/ | grep -c adapter0) -eq 1 ] && $dvbneeded; then
  echo "lxc.cgroup.devices.allow: c $(ls -la /dev/dvb/adapter0 | grep video | head -n1 | awk '{print $5}' | cut -d, -f1):* rwm" >> /etc/pve/lxc/$ctID.conf
  echo "lxc.mount.entry: /dev/dvb dev/dvb none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
fi

# Mounted the VGA-Card to container if exist and is needed
if [ $(ls -la /dev/dri/card0 | grep -c video) -eq 1 ] && $vganeeded; then
  echo "lxc.cgroup.devices.allow: c $(ls -la /dev/dri | grep video | head -n1 | awk '{print $5}' | cut -d, -f1):* rwm" >> /etc/pve/lxc/$ctID.conf
  echo "lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
  echo "lxc.mount.entry: /dev/dri/render$(ls -la /dev/dri | grep render | head -n1 | awk '{print $10}' | cut -d'r' -f3) dev/dri/render$(ls -la /dev/dri | grep render | head -n1 | awk '{print $10}' | cut -d'r' -f3) none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
fi

# Insert created Container in Backup Pool
pvesh set /pools/BackupPool -vms $ctID

# Start Container
pct start $ctID
sleep 10

# Disable SSH client option SendEnv LC_* because errors occur during automatic processing
pct exec $ctID -- bash -ci "sed -i 's+    SendEnv LANG LC_*+#   SendEnv LANG LC_*+g' /etc/ssh/ssh_config > /dev/null 2>&1"

# Mounted the NAS to container if exist and is set in Container Configuration Template
if [ -z "$var_nasip" ] && $nasneeded; then
    pct exec $ctID -- bash -ci "mkdir -p /media"
    pct exec $ctID -- bash -ci "mkdir -p /mnt/backup"
    pct exec $ctID -- bash -ci "echo \"//$var_nasip/media  /media  cifs  credentials=/home/.smbmedia,uid=1000,gid=1000  0  0\" >> /etc/fstab"
    pct exec $ctID -- bash -ci "echo \"//$var_nasip/backups  /mnt/backup  cifs  credentials=/home/.smbbackup,uid=1000,gid=1000  0  0\" >> /etc/fstab"
    pct exec $ctID -- bash -ci "echo -e \"username=$var_robotname\npassword=$var_robotpw\" > /home/.smbmedia"
    pct exec $ctID -- bash -ci "echo -e \"username=$var_robotname\npassword=$var_robotpw\" > /home/.smbbackup"
    pct exec $ctID -- bash -ci "mount -a"
  else
    echo "-- Es kann keine NAS an den Container gebunden werden, da keine konfiguriert ist"
  fi
fi

# Install Samba to Container if sambaneeded Variable is true
if $sambaneeded; then
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
echo "-- Der Container wird aktualisiert"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1"

# Install Container Standardsoftware
echo "-- Containersoftware wird installiert"
pct exec $ctID -- bash -ci "apt-get install -y curl wget software-properties-common apt-transport-https lsb-release gnupg2 net-tools > /dev/null 2>&1"

# Commands that are executed in the container
if [ -n "$lxcCommands" ]; then
  IFS=$'\n'
  for command in $lxcCommands; do
    pct exec $ctID -- bash -ci "$command"
  done
  unset IFS
fi

# Commands to be executes in the Host (Proxmox) shell after complete Container creation
if [ -n "$pveCommands" ]; then
  IFS=$'\n'
  for command in $pveCommands; do
    $command
  done
  unset IFS
fi

# Create Container description, you can find it on Proxmox WebGUI
echo "-- Die Containererstellung wird abgeschlossen"
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

if $sambaneeded; then
  echo -e "#\n#>> Samba (smb) <<\n#Windows-$lng_wrd_sharedfolder:   \\\\\\$networkIP.$ctIP\n#Mac-$lng_wrd_sharedfolder:       smb://$networkIP.$ctIP\n#Linux-$lng_wrd_sharedfolder:     smb://$networkIP.$ctIP" >> $lxcConfigFile
  echo -e "$smbuserdesc" >> $lxcConfigFile
fi
echo -e "$lxcConfigOld" >> $lxcConfigFile

# Create Firewall Group and Rules for Container
echo "Die Proxmox Firewall wird für den Container konfiguriert"
clusterfileFW="/etc/pve/firewall/cluster.fw"
echo -e "\n[group $(echo fwsg_$hostname_lxc | tr "[:upper:]" "[:lower:]")]" >> $clusterfileFW    # This Line will create the Firewall Goup Containername - don't change it

if $sambaneeded; then
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

echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP fwsg_$(echo $hostname_lxc|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw    # Allow generated Firewallgroup, don't change it

# Cleanup Container History an reboot
echo "Lösche Verlaufsdaten im Container"
pct exec $ctID -- bash -ci "cat /dev/null > ~/.bash_history"
pct exec $ctID -- bash -ci "history -c"
pct exec $ctID -- bash -ci "history -w"
pct reboot $ctID --timeout 5
exit 0