#!/bin/bash

var_language=$1
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

echoLOG y "${txt_0301}"
sleep 1
# if available, create linux bridge on second Network adapter for SmartHome VLAN
if [ -n "$smarthomenetadapter" ]; then
  echo "auto vmbr1" >> "/etc/network/interfaces"
  echo "iface vmbr1 inet static" >> "/etc/network/interfaces"
  echo "        address $(echo ${var_smarthomevlangw} | cut -d. -f1,2,3).$(echo ${pve_ip} | cut -d. -f4)/$(echo ${var_smarthomevlangw} | cut -d/ -f2)" >> "/etc/network/interfaces"
  echo "        gateway $(echo ${var_smarthomevlangw} | cut -d/ -f1)" >> "/etc/network/interfaces"
  echo "        bridge-ports ${smarthomenetadapter}" >> "/etc/network/interfaces"
  echo "        bridge-stp off" >> "/etc/network/interfaces"
  echo "        bridge-fd 0" >> "/etc/network/interfaces"
  systemctl restart networking
  sleep 2
fi

# if available, mount NAS in Proxmox and configure backups
pvesh create /pools --poolid BackupPool --comment "${txt_0302}"
if [ -n "$var_nasip" ]; then
  echoLOG b "${txt_0303}"
  i=6
  while [ pvesm add cifs backups --server "$var_nasip" --share "backups" --username "$var_robotname" --password "$var_robotpw" --content backup != 0 ] && [ $i != 0 ]; do
    echoLOG r "Deine NAS ist nicht bereit, bitte warten..."
    sleep 5
    i=$(( $i - 1 ))
    echoLOG b "Versuche erneut deine NAS einzubinden >> verbelibend $i"
  done
  if [ $i -eq 0 ]; then
    echoLOG r "Deine NAS konnte nicht als Backuplaufwerk eingebunden werden"
    echoLOG b "Bitte führe den folgenden Befehl im Anschluss manuell durch und ersetzte XXXXX durch das benötigte Passwort"
    echo -e "         pvesm add cifs backups --server \"$var_nasip\" --share \"backups\" --username \"$var_robotname\" --password \"XXXXX\" --content backup"
  fi
  echo "0 3 * * *   root   vzdump --compress zstd --mailto root --mailnotification always --exclude-path /mnt/ --exclude-path /media/ --mode snapshot --quiet 1 --pool BackupPool --maxfiles 6 --storage backups" >> /etc/cron.d/vzdump
fi

# Enable S.M.A.R.T. support on system hard drive
echoLOG b "${txt_0304}"
if [ $(smartctl -a /dev/$rootDisk | grep -c "SMART support is: Enabled") -eq 0 ]; then
  smartctl -s on -a /dev/$rootDisk
fi

# Set email notification about system hard disk errors, check every 12 hours
echoLOG b "${txt_0305}"
sed -i 's|#enable_smart="/dev/hda /dev/hdb"|enable_smart="/dev/'"$rootDisk"'"|' /etc/default/smartmontools
sed -i 's|#smartd_opts="--interval=1800"|smartd_opts="--interval=43200"|' /etc/default/smartmontools
echo "start_smartd=yes" >> /etc/default/smartmontools
sed -i 's|DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner|#DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner|' /etc/smartd.conf
sed -i 's|# /dev/sda -a -d sat|/dev/'"$rootDisk"' -a -d sat|' /etc/smartd.conf
sed -i 's|#/dev/sda -d scsi -s L/../../3/18|/dev/'"$rootDisk"' -d sat -s L/../../1/02 -m root|' /etc/smartd.conf
systemctl start smartmontools

# configure Firewall in Proxmox
echoLOG b "${txt_0306}"
mkdir -p /etc/pve/firewall
mkdir -p /etc/pve/nodes/$pve_hostname
# Cluster level firewall
if [ -z "${var_servervlanid}" ]; then
  echo -e "[OPTIONS]\nenable: 1\n\n[IPSET network] # ${wrd_0005}\n$networkIP.0/$cidr\n\n[IPSET pnetwork] # ${txt_0307}\n10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16\n\n[RULES]\nGROUP proxmox\n\n[group proxmox]\nIN SSH(ACCEPT) -source +network -log nolog\nIN ACCEPT -source +pnetwork -p tcp -dport 8006 -log nolog\nIN ACCEPT -source +pnetwork -p tcp -dport 5900:5999 -log nolog\nIN ACCEPT -source +pnetwork -p tcp -dport 3128 -log nolog\nIN ACCEPT -source +pnetwork -p udp -dport 111 -log nolog\nIN ACCEPT -source +pnetwork -p udp -dport 5404:5405 -log nolog\nIN ACCEPT -source +pnetwork -p tcp -dport 60000:60050 -log nolog\n\n" > $clusterfileFW
else
  echo -e "[OPTIONS]\nenable: 1\n\n[IPSET network] # ${wrd_0005}\n$(echo $var_servervlangw | cut -d. -f1,2,3).0/$(echo $var_servervlangw | cut -d/ -f2)\n$(echo $var_dhcpvlangw | cut -d. -f1,2,3).0/$(echo $var_dhcpvlangw | cut -d/ -f2)\n\n[IPSET pnetwork] # ${txt_0307}\n10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16\n\n[RULES]\nGROUP proxmox\n\n[group proxmox]\nIN SSH(ACCEPT) -source +network -log nolog\nIN ACCEPT -source +pnetwork -p tcp -dport 8006 -log nolog\nIN ACCEPT -source +pnetwork -p tcp -dport 5900:5999 -log nolog\nIN ACCEPT -source +pnetwork -p tcp -dport 3128 -log nolog\nIN ACCEPT -source +pnetwork -p udp -dport 111 -log nolog\nIN ACCEPT -source +pnetwork -p udp -dport 5404:5405 -log nolog\nIN ACCEPT -source +pnetwork -p tcp -dport 60000:60050 -log nolog\n\n" > $clusterfileFW
fi
# Host level Firewall
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP proxmox\n\n" > $hostfileFW

# configure the second hard disk if exists and is an SSD
if [ -z $secondDisk ]; then
  echoLOG b "${txt_0308}"
  parted -s /dev/$secondDisk "mklabel gpt" > /dev/null 2>&1
  parted -s -a opt /dev/$secondDisk mkpart primary ext4 0% 100% > /dev/null 2>&1
  mkfs.ext4 -Fq -L data /dev/"$secondDisk"1 > /dev/null 2>&1
  mkdir -p /mnt/data > /dev/null 2>&1
  mount -o defaults /dev/"$secondDisk"1 /mnt/data > /dev/null 2>&1
  echo "UUID=$(lsblk -o LABEL,UUID | grep 'data' | awk '{print $2}') /mnt/data ext4 defaults 0 2" >> /etc/fstab
  pvesm add dir data --path /mnt/data
  pvesm set data --content iso,vztmpl,rootdir,images

  # Set email notification about hard disk errors, check every 12 hours
  sed -i 's|enable_smart="/dev/'"$rootDisk"'"|enable_smart="/dev/'"$rootDisk"' /dev/'"$secondDisk"'"|' /etc/default/smartmontools
  sed -i 's|/dev/'"$rootDisk"' -a -d sat|/dev/'"$rootDisk"' -a -d sat\n/dev/'"$secondDisk"' -a -d sat|' /etc/smartd.conf
  sed -i 's|#/dev/sdb -d scsi -s L/../../7/01|/dev/'"$secondDisk"' -d sat -s L/../../1/03 -m root|' /etc/smartd.conf
  systemctl restart smartmontools
fi

if bash $script_path/bin/config_email.sh; then
  echoLOG g "${txt_0315}"
else
  echoLOG r "${txt_0316}"
fi

# save Configfile to NAS
if [ -n "$var_nasip" ]; then
  echoLOG p "${txt_0311}"
  cp $shiot_configPath/$shiot_configFile /mnt/pve/backups/SHIoT_configuration.txt > /dev/null 2>&1
fi

# mail Configfile to root
echoLOG p "${txt_0312}"
cp $shiot_configPath/$shiot_configFile /tmp/SHIoT_configuration.txt
sed -i 's|var_robotpw=".*"|var_robotpw=""|g' /tmp/SHIoT_configuration.txt
sed -i 's|var_mailpassword=".*"|var_mailpassword=""|g' /tmp/SHIoT_configuration.txt
echo -e "${txt_0313} \"SHIoT_configuration.txt\". ${txt_0314}" | mail.mailutils -a "From: \"${wrd_0006}\" <${var_senderaddress}>" -s "[SHIoT] ${wrd_0008}" "$var_rootmail" -A "/tmp/SHIoT_configuration.txt"


exit 0
