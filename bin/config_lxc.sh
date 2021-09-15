#!/bin/bash

var_language=$1
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

ctID=$2
ctIP=$3
ctRootpw="$4"
containername="$5"

source "$script_path/lxc/$containername/generate.sh"

# If Container Language Folder exist, load container language file if, not exist load english language
if [ -d "$script_path/lxc/$containername/language" ]; then
  if [ -f "$script_path/lxc/$containername/language/$var_language.sh" ]; then
    source "$script_path/lxc/$containername/language/$var_language.sh"
  else
    source "$script_path/lxc/$containername/language/en.sh"
  fi
fi

echoLOG y "${txt_0201}"

# Ask for SMTP-Password if SMTP is needed and Passwort is not save in shiot_configFile
if $smtpneeded; then
  if [ -z "$var_mailpassword" ]; then
    var_mailpassword=$(whiptail --passwordbox --ok-button " ${btn_1} " --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0005} " "\n${txt_0202}" 10 80 3>&1 1>&2 2>&3)
  fi
fi

# Changes the App Armor profile for the container
if [ -n "$apparmorProfile" ]; then
  sed -i 's|swap: '"$swap"'|swap: '"$swap"'\nlxc.apparmor.profile: '"$apparmorProfile"'|' /etc/pve/lxc/$ctID.conf > /dev/null 2>&1
fi

# Add another network card in the SmartHome network, if possible and required.
if [ -n "${var_smarthomevlanid}" ] && $smarthomeVLAN; then
  echoLOG b "${txt_0216}"
  pct set $ctID --net1 name=eth1,bridge=vmbr1,firewall=1,gw=$(echo $var_smarthomevlangw | cut -d/ -f1),ip=$(echo $var_smarthomevlangw | cut -d. -f1,2,3).$ctIP/$(echo $var_smarthomevlangw | cut -d/ -f2) > /dev/null 2>&1
fi

# Add another network card in the guest network, if possible and required.
if [ -n "${var_guestvlangw}" ] && $guestVLAN; then
  echoLOG b "${txt_0217}"
  pct set $ctID --net1 name=eth1,bridge=vmbr1,firewall=1,gw=$(echo $var_guestvlangw | cut -d/ -f1),ip=$(echo $var_guestvlangw | cut -d. -f1,2,3).$ctIP/$(echo $var_guestvlangw | cut -d/ -f2) > /dev/null 2>&1
fi

# Mounted the DVB-TV-Card to container if exist and is needed
if [ $(ls -la /dev/dvb/ | grep -c adapter0) -eq 1 ] && $dvbneeded; then
  echoLOG b "${txt_0203}"
  echo "lxc.cgroup.devices.allow: c $(ls -la /dev/dvb/adapter0 | grep video | head -n1 | awk '{print $5}' | cut -d, -f1):* rwm" >> /etc/pve/lxc/$ctID.conf
  echo "lxc.mount.entry: /dev/dvb dev/dvb none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
fi

# Mounted the VGA-Card to container if exist and is needed
if [ $(ls -la /dev/dri/card0 | grep -c video) -eq 1 ] && $vganeeded; then
  echoLOG b "${txt_0204}"
  echo "lxc.cgroup.devices.allow: c $(ls -la /dev/dri | grep video | head -n1 | awk '{print $5}' | cut -d, -f1):* rwm" >> /etc/pve/lxc/$ctID.conf
  echo "lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
  echo "lxc.mount.entry: /dev/dri/render$(ls -la /dev/dri | grep render | head -n1 | awk '{print $10}' | cut -d'r' -f3) dev/dri/render$(ls -la /dev/dri | grep render | head -n1 | awk '{print $10}' | cut -d'r' -f3) none bind,optional,create=dir" >> /etc/pve/lxc/$ctID.conf
fi

# Insert created Container in Backup Pool
echoLOG b "${txt_0205}"
pvesh set /pools/BackupPool -vms $ctID

# Start Container
echoLOG b "${txt_0206}"
pct start $ctID
sleep 10

# Disable SSH client option SendEnv LC_* because errors occur during automatic processing
pct exec $ctID -- bash -ci "sed -i 's|    SendEnv LANG LC_*|#   SendEnv LANG LC_*|g' /etc/ssh/ssh_config > /dev/null 2>&1"

# Mounted the NAS to container if exist and is set in Container Configuration Template
if [ -n "$var_nasip" ] && $nasneeded; then
  echoLOG b "${txt_0207}"
  pct exec $ctID -- bash -ci "mkdir -p /media"
  pct exec $ctID -- bash -ci "mkdir -p /mnt/backup"
  mkdir -p "/mnt/pve/backups/${containername}/"
  pct exec $ctID -- bash -ci "echo \"//$var_nasip/media  /media  cifs  credentials=/home/.smbmedia,uid=1000,gid=1000  0  0\" >> /etc/fstab"
  pct exec $ctID -- bash -ci "echo \"//$var_nasip/backups/$containername  /mnt/backup  cifs  credentials=/home/.smbbackup,uid=1000,gid=1000  0  0\" >> /etc/fstab"
  pct exec $ctID -- bash -ci "echo -e \"username=$var_robotname\npassword=$var_robotpw\" > /home/.smbmedia"
  pct exec $ctID -- bash -ci "echo -e \"username=$var_robotname\npassword=$var_robotpw\" > /home/.smbbackup"
  pct exec $ctID -- bash -ci "mount -a"
fi
if [ -z "$var_nasip" ] && $nasneeded; then echoLOG r "${txt_0208}"; fi

# Install Samba to Container if sambaneeded Variable is true
if $sambaneeded; then
  echoLOG b "${txt_0208}"
  smbuserdesc=""
  pct exec $ctID -- bash -ci "apt-get install -y samba samba-common-bin > /dev/null 2>&1"
  for user in $sambaUser; do
    smbpasswd=$(generatePassword 8)
    pct exec $ctID -- bash -ci "adduser --no-create-home --disabled-login --shell /bin/false $user"
    pct exec $ctID -- bash -ci "( echo \"$smbpasswd\"; sleep 1; echo \"$smbpasswd\" ) | sudo smbpasswd -s -a $user"
    pct exec $ctID -- bash -ci "mkdir -p /root/sambashare/$user"
    pct exec $ctID -- bash -ci "echo -e \"\n[$user]\ncomment = Sambashare\npath = /root/sambashare/$user\nwrite list = $user\nvalid users = $user\nforce user = smb\" >> /etc/samba/smb.conf"
    if [ -z "$smbuserdesc" ]; then
      smbuserdesc="#$wrd_0011:   $user\n#$wrd_0004:   $smbpasswd"
    else
      smbuserdesc="${smbuserdesc}\n#$wrd_0011:   $user\n#$wrd_0004:   $smbpasswd"
    fi
  done
  pct exec $ctID -- bash -ci "sed -i 's|map to guest = bad user|map to guest = never|' /etc/samba/smb.conf > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "chown -R smb /root/sambashare"
  pct exec $ctID -- bash -ci "systemctl restart smbd.service"
fi

# Update/Upgrade Container
echoLOG b "${txt_0209}"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1"

# Execute config. in Container dir to config Container
echoLOG "${txt_0210}"
if ! "$script_path/lxc/$containername/config.sh" ${ctID} ${ctIP} "${ctRootpw}" "${containername}"; then exit 1; fi

# Create Container description, you can find it on Proxmox WebGUI
# Find ASCII URL-Encoding at https://www.key-shortcut.com/zeichentabellen/ascii-url-kodierung
echoLOG "${txt_0211}"
lxcConfigFile="/etc/pve/lxc/$ctID.conf"
lxcConfigOld=$(cat $lxcConfigFile)

source "$script_path/lxc/$containername/description.sh"

desc="desc_${var_language}"
if [ -z "${!desc}" ]; then desc="desc_en"; fi

echo -e "#### ${!desc} ###\n####### Shell ######\n#%09$wrd_0011%3A   root\n#%09$wrd_0004%3A   ${ctRootpw}\n#" > $lxcConfigFile

if $webgui; then
  for ((i=0;i<=${#webguiPort[@]};i++)); do
    if [[ ${webguiPort[i]} == "" ]]; then webguiAdress="${webguiProt[i]}%3A%2F%2F$(echo $pve_ip | cut -d. -f1,2,3).$ctIP"; else webguiAdress="${webguiProt[i]}%3A%2F%2F$(echo $pve_ip | cut -d. -f1,2,3).$ctIP:${webguiPort[i]}"; fi
    if [[ ! ${webguiPath[i]} == "" ]]; then webguiAdress="${webguiAdress}${webguiPath[i]}"; fi
    if [[ ! ${webguiName[i]} == "" ]]; then
      if [ $i -lt 1 ]; then
        echo -e "#\n####### ${webguiName[i]} ######\n#%09$wrd_0012%3A $webguiAdress" >> $lxcConfigFile
      else
        echo -e "####### ${webguiName[i]} ######\n#%09$wrd_0012%3A $webguiAdress" >> $lxcConfigFile
      fi
    fi
    if [[ ! ${webguiUser[i]} == "" ]]; then echo -e "#%09$wrd_0011%3A   ${webguiUser[i]}" >> $lxcConfigFile; fi
    if [[ ! ${webguiPass[i]} == "" ]]; then echo -e "#%09$wrd_0004%3A   ${webguiPass[i]}" >> $lxcConfigFile; fi
  done
fi

if [ -n "$var_nasip" ] && $nasneeded; then
  echo -e "#\n####### $wrd_0013 ######\n#%09$wrd_0014%3A   %2Fmedia\n#%09$wrd_0015%3A   %2Fmnt%2Fbackup" >> $lxcConfigFile
fi

if $sambaneeded; then
  echo -e "#\n####### Samba (smb) ######\n#%09Windows-$wrd_0016%3A   %5C%5C$(echo $pve_ip | cut -d. -f1,2,3).$ctIP\n#%09Mac-$wrd_0016%3A       smb%3A%2F%2F$(echo $pve_ip | cut -d. -f1,2,3).$ctIP\n#%09Linux-$wrd_0016%3A     smb%3A%2F%2F$(echo $pve_ip | cut -d. -f1,2,3).$ctIP" >> $lxcConfigFile
  echo -e "$smbuserdesc" >> $lxcConfigFile
fi
echoLOG b "${txt_0212}"
echo -e "$lxcConfigOld" >> $lxcConfigFile

# Send an email to the user when he needs to complete tasks manually 
if [ -n "$commandsAfterCFG" ]; then
  echoLOG r "${txt_0213}"
  mailbody="mail_${var_language}"
  if [ -z "${!mailbody}" ]; then mailbody="mailbody_en"; fi
  echo -e "${!mailbody}\n\n${commandsAfterCFG}" | mail -a "From: \"${wrd_0006}\" <${var_senderaddress}>" -s "[SHIoT] ${containername} - ${!desc}" "$var_rootmail"
fi

# Create Firewall Group and Rules for Container
echoLOG b "${txt_0214}"
clusterfileFW="/etc/pve/firewall/cluster.fw"
if [ $(cat $clusterfileFW | grep -cw fwsg_$containername) -eq 0 ]; then
  echo -e "\n[group $(echo fwsg_$containername | tr "[:upper:]" "[:lower:]")]" >> $clusterfileFW    # This Line will create the Firewall Goup Containername - don't change it

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
fi

if [ ! -f "/etc/pve/firewall/$ctID.fw" ]; then touch "/etc/pve/firewall/$ctID.fw"; fi

if [ $(cat /etc/pve/firewall/$ctID.fw | grep -cw fwsg_$containername) -eq 0 ]; then
  echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP fwsg_$(echo $containername | tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw    # Allow generated Firewallgroup, don't change it
fi

# Cleanup Container History an reboot
echoLOG "${txt_0215}"
pct exec $ctID -- bash -ci "cat /dev/null > ~/.bash_history"
pct exec $ctID -- bash -ci "history -c"
pct exec $ctID -- bash -ci "history -w"
pct reboot $ctID --timeout 5

exit 0
