#!/bin/bash

# General Variables
shiot_configPath="/opt/smarthome-iot_net"
shiot_configFile=".config.sh"
pve_majorversion=$(pveversion | cut -d/ -f2 | cut -d. -f1)
pve_version=$(pveversion | cut -d/ -f2 | cut -d- -f1)

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
timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')

# Hardware Variables
rootDisk=$(eval $(lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"'); echo $PKNAME | sed 's/[0-9]*$//')

# check if Variable is valid URL
regexURL='^(https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'  # if [[ ! $URL =~ $regexURL ]]; then; fi

# colorize the Shell
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'
