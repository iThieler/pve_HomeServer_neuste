#!/bin/bash

source "bin/variables.sh"
source "bin/var_containerOS.sh"
source "handler/global_functions.sh"
source "lxc/_list.sh.sh"
source "$shiot_configPath/$shiot_configFile"

function createContainer() {
# Generates ID and IP-Address for the container to be created if is not the first
  echo "Erzeuge Container ID & IP"
  if [ $(pct list | grep -cw 100) -eq 1 ]; then
    ctIDLast=$(pct list | tail -n1 | awk '{print $1}')
    ctIPLast=$(lxc-info $ctIDLast -iH | cut -d. -f4 | tail +2)
    ctID=$(( $ctIDLast +1 ))
    ctIP=$(( $ctIPLast +1 ))
  fi

# Get rootfs
  if [[ $ctTemplateDisk == "local" ]]; then
    rootfs="local-lvm"
  else
    rootfs=$ctTemplateDisk
  fi

# Create Container from Template File download Template OS if not exist
  echo "Containererstellung wird vorbereitet"
  lxcTemplateName="$(pveam available | grep "$template" | awk '{print $2}')"
  
  if [[ $template == "osDevuan" ]]; then
    osType="unmanaged"
  else
    osType=$(pveam available | grep "$template" | awk '{print $2}' | cut -d- -f1)
  fi
  
  if [ $(pveam list "$ctTemplateDisk" | grep -c "$template") -eq 0 ]; then
    echo "Containertemplate ist nicht vorhanden. Download beginnt"
    pveam download $ctTemplateDisk $lxcTemplateName > /dev/null 2>&1
  fi

  pctCreateCommand="$ctTemplateDisk:vztmpl/$lxcTemplateName \
                    --ostype "$osType" \
                    --hostname $hostname_lxc \
                    --password \"$ctRootPW\" \
                    --rootfs $rootfs:$hddsize \
                    --cores $cpucores \
                    --memory $memory \
                    --swap $swap \
                    --net0 name=eth0,bridge=vmbr0,firewall=1,gw=$gatewayIP,ip=$networkIP.$ctIP/$cidr,ip6=dhcp \
                    --onboot 1 \
                    --force 1 \
                    --unprivileged $unprivileged \
                    --start 0"
  if [ -n "$features" ]; then pctCreateCommand="$pctCreateCommand --features $features"; fi
  pctCreateCommand="$( echo $pctCreateCommand | sed -e 's#                     # #g')"

  echo -e "Der Container \"$hostname_lxc\" wird erstellt. Er erhält die ID \"$ctID\""
  pct create $ctID $pctCreateCommand > /dev/null 2>&1
  sleep 10
}
