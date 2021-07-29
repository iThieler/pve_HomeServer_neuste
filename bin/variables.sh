#!/bin/bash

shiot_configPath="/opt/smarthome-iot_net/"
shiot_configFile=".config.sh"
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

