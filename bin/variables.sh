#!/bin/bash

# General Variables
shiot_configPath="/opt/smarthome-iot_net"
shiot_configFile=".config.sh"
script_path="/root/pve_HomeServer"
#script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
pve_majorversion=$(pveversion | cut -d/ -f2 | cut -d. -f1)
pve_version=$(pveversion | cut -d/ -f2 | cut -d- -f1)
networkIP=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f1,2,3)

# Network Variables
gatewayIP=$(ip r | grep default | cut -d" " -f3)
pve_ip=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1)
cidr=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f2)
networkIP=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f1,2,3)
publicIP=$(dig @resolver4.opendns.com myip.opendns.com +short)
pve_fqdn=$(hostname -f)
pve_hostname=$(hostname)

# Proxmox Variables
clusterfileFW="/etc/pve/firewall/cluster.fw"
hostfileFW="/etc/pve/nodes/$pve_hostname/host.fw"
pve_timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
pve_osname=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d= -f2)

# Hardware Variables
rootDisk=$(lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"' | cut -d' ' -f2 | cut -d\" -f2 | sed 's#[0-9]*$##')

# search second Harddisk and check if is SSD
if [[ $(cat /sys/block/$(lsblk -nd --output NAME | grep "s" | sed "s#$rootDisk##" | sed ':M;N;$!bM;s#\n##g')/queue/rotational) -eq 0 ]]; then
  secondDisk=$(lsblk -nd --output NAME | grep "s" | sed "s#$rootDisk##" | sed ':M;N;$!bM;s#\n##g')
  ctTemplateDisk="data"
else
  ctTemplateDisk="local"
fi

# check if Variable is valid URL
regexURL='^(https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'  # if [[ ! $URL =~ $regexURL ]]; then; fi