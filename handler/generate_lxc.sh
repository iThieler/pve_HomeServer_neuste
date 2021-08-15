#!/bin/bash

source "/root/pve_HomeServer/bin/variables.sh"
source "$script_path/bin/var_containerOS.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"

ctRootPW=""

# make list of available Containers, hide already existing
available_lxc=$(find $script_path/lxc/* -prune -type d | while IFS= read -r d; do echo -e "$d"; done | sed -e "s#$script_path/lxc/##g" | sed ':M;N;$!bM;s#\n# #g')
echo -e "#!/bin/bash\n\nlxc_list=( \\" > /tmp/lxclist.sh
for lxc in $available_lxc; do
  description=$(cat "$script_path/lxc/${lxc}/description.txt" | sed -n '1p')
  if [ $(cat "$script_path/lxc/${lxc}/description.txt" | grep -cw "nas") -eq 0 ]; then
    if [[ $(pct list | grep -cw "${lxc}") -eq 0 ]]; then
      echo -e "\"${lxc}\" \"${description}\" off \\" >> /tmp/lxclist.sh
    else
      echo -e "\"${lxc}\" \"${description}\" on \\" >> /tmp/lxclist.sh
    fi
  fi
  if [ $(cat "$script_path/lxc/${lxc}/description.txt" | grep -cw "nas") -eq 1 ] && [ -n $var_nasip ]; then
    if [[ $(pct list | grep -cw "${lxc}") -eq 0 ]]; then
      echo -e "\"${lxc}\" \"${description}\" off \\" >> /tmp/lxclist.sh
    else
      echo -e "\"${lxc}\" \"${description}\" on \\" >> /tmp/lxclist.sh
    fi
  fi
done
echo -e ")" >> /tmp/lxclist.sh

source /tmp/lxclist.sh

# Get Container rootfs
if [[ $ctTemplateDisk == "local" ]]; then
  rootfs="local-lvm"
else
  rootfs=$ctTemplateDisk
fi

function create() {
  containername="$1"
  # Load Container generate Variables
  source "$script_path/lxc/${containername}/var_generate.sh"

  # Generates ID and IP-Address for the container to be created if is not the first
  if [ $(pct list | grep -cw 100) -eq 1 ]; then
    ctIDLast=$(pct list | tail -n1 | awk '{print $1}')
    ctIPLast=$(lxc-info $ctIDLast -iH | cut -d. -f4 | tail +2)
    ctID=$(( $ctIDLast +1 ))
    ctIP=$(( $ctIPLast +1 ))
  fi

  # Create Container from Template File download Template OS if not exist
  lxcTemplateName="$(pveam available | grep "${template}" | awk '{print $2}')"

  if [[ $template == "osDevuan" ]]; then
    osType="unmanaged"
  else
    osType=$(pveam available | grep "$template" | awk '{print $2}' | cut -d- -f1)
  fi

  if [ $(pveam list "$ctTemplateDisk" | grep -c "$template") -eq 0 ]; then
    pveam download $ctTemplateDisk $lxcTemplateName > /dev/null 2>&1
  fi

  pctCreateCommand="$ctTemplateDisk:vztmpl/$lxcTemplateName \
                    --ostype "$osType" \
                    --hostname $containername \
                    --description $(cat $script_path/lxc/$containername/description.txt | sed -n '1p') \
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

  pct create $ctID $pctCreateCommand > /dev/null 2>&1
  sleep 10
  if [ pct list | grep -cw $containername -eq 1 ]; then
    echo -e "- Der Container \"$containername\" wurde mit der ID \"$ctID\" erstellt"
    if "$script_path/bin/config_lxc.sh" $ctID; then
      echo -e "- Der Container \"$containername\" wurde konfiguriert"
    else
      echo -e "- Der Container \"$containername\" konnte nicht konfiguriertwerden"
    fi
  else
    echo -e "- Der Container \"$containername\" konnte nicht erstellt werden"
  fi
}

var_lxcchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_6} " "\nWähle die Container, die Du installieren möchtest. Aktivierte Container sind bereits installiert,wenn Du sie deaktivierst werden sie deinstalliert." 20 80 10 "${lxc_list[@]}" 3>&1 1>&2 2>&3)

# delete available Container not choosen
lxc_available=$(pct list | awk -F ' ' '{print $NF}' | tail -n +2 | while IFS= read -r d; do echo -e "$d"; done | sed ':M;N;$!bM;s#\n# #g')
for available_lxc in $lxc_available; do
  if [[ ! "$available_lxc" =~ ^($var_lxcchoice)$ ]]; then
    pct destroy $(pct list | grep -w "$available_lxc" | awk '{print $1}') --force 1 --purge 1
  fi
done

# create choosen Container
for choosed_lxc in $var_lxcchoice; do
  if [ $(pct list | grep -cw "$choosed_lxc") -eq 0 ]; then
    ctRootPW="$(generatePassword 12)"
    create $choosed_lxc $ctRootPW
  else
    echo -e "- Der Container \"$choosed_lxc\" konnte nicht erstellt werden, da er schon existiert"
  fi
done
