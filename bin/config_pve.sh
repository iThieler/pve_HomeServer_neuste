#!/bin/bash

script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"

# ask User for Script Language
if [ -z "$var_language" ]; then
  var_language=$(whiptail --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --menu "" 20 80 10 "${lng[@]}" 3>&1 1>&2 2>&3)
  source "$script_path/language/$var_language.sh"
else
  source "$script_path/language/$var_language.sh"
fi

sleep 5
# if available, mount NAS in Proxmox
if [ -n "$var_nasip" ]; then
  echo "-- ${txt_0101}"
  pvesm add cifs backups --server "$var_nasip" --share "backups" --username "$var_robotname" --password "$var_robotpw" --content backup
  pvesh create /pools --poolid BackupPool --comment "${txt_0102}"
  echo "0 3 * * *   root   vzdump --compress zstd --mailto root --mailnotification always --exclude-path /mnt/ --exclude-path /media/ --mode snapshot --quiet 1 --pool BackupPool --maxfiles 6 --storage backups" >> /etc/cron.d/vzdump
fi

# Enable S.M.A.R.T. support on system hard drive
echo "-- ${txt_0104}"
if [ $(smartctl -a /dev/$rootDisk | grep -c "SMART support is: Enabled") -eq 0 ]; then
  smartctl -s on -a /dev/$rootDisk
fi

# Set email notification about system hard disk errors, check every 12 hours
echo "-- ${txt_0105}"
sed -i 's+#enable_smart="/dev/hda /dev/hdb"+enable_smart="/dev/'"$rootDisk"'"+' /etc/default/smartmontools
sed -i 's+#smartd_opts="--interval=1800"+smartd_opts="--interval=43200"+' /etc/default/smartmontools
echo "start_smartd=yes" >> /etc/default/smartmontools
sed -i 's+DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner+#DEVICESCAN -d removable -n standby -m root -M exec /usr/share/smartmontools/smartd-runner+' /etc/smartd.conf
sed -i 's+# /dev/sda -a -d sat+/dev/'"$rootDisk"' -a -d sat+' /etc/smartd.conf
sed -i 's+#/dev/sda -d scsi -s L/../../3/18+/dev/'"$rootDisk"' -d sat -s L/../../1/02 -m root+' /etc/smartd.conf
systemctl start smartmontools

# configure Firewall in Proxmox
echo "-- ${txt_0106}"
mkdir -p /etc/pve/firewall
mkdir -p /etc/pve/nodes/$pve_hostname
# Cluster level firewall
echo -e "[OPTIONS]\nenable: 1\n\n[IPSET network] # ${wrd_3}\n$networkIP.0/$cidr\n\n[IPSET pnetwork] # ${txt_0107}\n10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16\n\n[RULES]\nGROUP proxmox\n\n[group proxmox]\nIN SSH(ACCEPT) -source +network -log nolog\nIN ACCEPT -source +network -p tcp -dport 8006 -log nolog\n\n" > $clusterfileFW
# Host level Firewall
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP proxmox\n\n" > $hostfileFW

# configure the second hard disk if exists and is an SSD
if [ -z $secondDisk ]; then
  echo "-- ${txt_0108}"
  parted -s /dev/$secondDisk "mklabel gpt" > /dev/null 2>&1
  parted -s -a opt /dev/$secondDisk mkpart primary ext4 0% 100% > /dev/null 2>&1
  mkfs.ext4 -Fq -L data /dev/"$secondDisk"1 > /dev/null 2>&1
  mkdir -p /mnt/data > /dev/null 2>&1
  mount -o defaults /dev/"$secondDisk"1 /mnt/data > /dev/null 2>&1
  echo "UUID=$(lsblk -o LABEL,UUID | grep 'data' | awk '{print $2}') /mnt/data ext4 defaults 0 2" >> /etc/fstab
  pvesm add dir data --path /mnt/data
  pvesm set data --content iso,vztmpl,rootdir,images

  # Set email notification about hard disk errors, check every 12 hours
  sed -i 's+enable_smart="/dev/'"$rootDisk"'"+enable_smart="/dev/'"$rootDisk"' /dev/'"$secondDisk"'"+' /etc/default/smartmontools
  sed -i 's+/dev/'"$rootDisk"' -a -d sat+/dev/'"$rootDisk"' -a -d sat\n/dev/'"$secondDisk"' -a -d sat+' /etc/smartd.conf
  sed -i 's+#/dev/sdb -d scsi -s L/../../7/01+/dev/'"$secondDisk"' -d sat -s L/../../1/03 -m root+' /etc/smartd.conf
  systemctl restart smartmontools
fi

if bash $script_path/bin/config_email.sh; then
  echo "- ${txt_0109}"
else
  echo "- ${txt_0110}"
fi

exit 0
