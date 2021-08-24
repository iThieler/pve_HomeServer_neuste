#!/bin/bash

source "$script_path/bin/variables.sh"
source "$script_path/bin/var_containerOS.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

ctRootPW=""

# make list of available Containers, hide already existing
echo "- ${txt_0201}"
available_lxc=$(find $script_path/lxc/* -prune -type d ! -path "$script_path/lxc/_*" ! -path "$script_path/lxc/0_*" | while IFS= read -r d; do echo -e "$d"; done | sed -e "s#$script_path/lxc/##g" | sed ':M;N;$!bM;s#\n# #g')
echo -e "#!/bin/bash\n\nlxc_list=( \\" > /tmp/lxclist.sh
desc="desc_${var_language}"
if [ -n "${!desc}" ]; then desc="desc_en"; fi 
for lxc in $available_lxc; do
  source "$script_path/lxc/${lxc}/description.sh"
  if [ -z "$var_nasip" ] && ! $nasonly; then
    if [[ $(pct list | grep -cw "${lxc}") -eq 0 ]]; then
      echo -e "\"${lxc}\" \""${!desc}  "\" off \\" >> /tmp/lxclist.sh
    fi
  elif [ -n "$var_nasip" ] && ! $nasonly; then
    if [[ $(pct list | grep -cw "${lxc}") -eq 0 ]]; then
      echo -e "\"${lxc}\" \""${!desc}  "\" off \\" >> /tmp/lxclist.sh
    fi
  elif [ -n "$var_nasip" ] && $nasonly; then
    if [[ $(pct list | grep -cw "${lxc}") -eq 0 ]]; then
      echo -e "\"${lxc}\" \""${!desc}  "\" off \\" >> /tmp/lxclist.sh
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
  containername=$1
  ctRootpw="$2"
  # Load container language file if not exist load english language
  if [ -d "$script_path/lxc/${containername}/language/" ]; then
    if "$script_path/lxc/${containername}/language/$var_language.sh"; then
      source "$script_path/lxc/${containername}/language/$var_language.sh"
    else
      source "$script_path/lxc/${containername}/language/en.sh"
    fi
  fi

  # Load Container generate Variables
  source "$script_path/lxc/${containername}/generate.sh"

  # Generates ID and IP-Address for the container to be created if is not the first
  if [ $(pct list | grep -cw 100) -eq 0 ]; then
    ctID=100
    ctIPLast=$(echo $pve_ip | cut -d. -f4)
    ctIP=$(( $ctIPLast +5 ))
  else
    ctIDLast=$(pct list | tail -n1 | awk '{print $1}')
    ctIPLast=$(lxc-info $ctIDLast -iH | grep $networkIP | cut -d. -f4)
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
                    --password "$ctRootpw" \
                    --rootfs $rootfs:$hddsize \
                    --cores $cpucores \
                    --memory $memory \
                    --swap $swap \
                    --net0 name=eth0,bridge=vmbr0,firewall=1,gw=$gatewayIP,ip=$networkIP.$ctIP/$cidr,ip6=dhcp \
                    --onboot 1 \
                    --force 1 \
                    --unprivileged $unprivileged \
                    --start 1"
  if [ -n "$features" ]; then pctCreateCommand="$pctCreateCommand --features $features"; fi
  pctCreateCommand="$( echo $pctCreateCommand | sed -e 's#                     # #g')"
  pct create $ctID $pctCreateCommand > /dev/null 2>&1
  sleep 5
  if [ $(pct list | grep -cw $containername) -eq 1 ]; then
    echo -e "- ${txt_0202}:\n  ${wrd_7}: $ctID\n  ${wrd_6}: $containername"
    pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1"
    if [[ $osType == "debian" ]]; then
      pct exec $ctID -- bash -ci "sed -i 's+#PermitRootLogin prohibit-password+PermitRootLogin yes+' /etc/ssh/sshd_config > /dev/null 2>&1"
      #pct exec $ctID -- bash -ci "service sshd restart"
    fi
    # Install Container Standardsoftware
    echo "-- $txt_0253"
    pct exec $ctID -- bash -ci "apt-get install -y curl wget software-properties-common apt-transport-https lsb-core lsb-release gnupg2 net-tools nfs-common cifs-utils > /dev/null 2>&1"
    pct shutdown $ctID --forceStop 1 > /dev/null 2>&1
    sleep 5
    if "$script_path/bin/config_lxc.sh" ${ctID} ${ctIP} "${ctRootpw}" "${containername}"; then
      echo -e "- ${txt_0203}"
    else
      echo -e "- ${txt_0204}"
    fi
  else
    echo -e "- ${txt_0205}"
  fi
}

var_lxcchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_6} " "\n${txt_0206}" 20 80 15 "${lxc_list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

for choosed_lxc in $var_lxcchoice; do
  if [ $(pct list | grep -cw "$choosed_lxc") -eq 0 ]; then
    ctRootPW="$(generatePassword 12)"
    create $choosed_lxc $ctRootPW
  else
    echo -e "- ${txt_0207}:\n  ${wrd_7}: $ctID\n  ${wrd_6}: $choosed_lxc"
  fi
done

exit 0
