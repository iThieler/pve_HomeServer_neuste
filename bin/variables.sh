#!/bin/bash

shiot_configPath="/opt/smarthome-iot_net/"
shiot_configFile=".config.sh"
pve_majorversion=$(pveversion | cut -d/ -f2 | cut -d. -f1)
pve_version=$(pveversion | cut -d/ -f2 | cut -d- -f1)
networkIP=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1 | cut -d. -f1,2,3)