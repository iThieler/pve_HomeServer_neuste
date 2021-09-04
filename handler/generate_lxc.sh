#!/bin/bash

var_language=$1
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$script_path/helper/containerOS.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

ctRootPW=""

# make list of available Containers, hide already existing
echoLOG b "${txt_0901}"
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

  echoLOG y "${txt_0903}"
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
    ctIP=$(( $(echo $pve_ip | cut -d. -f4) + 5 ))
  else
    ctID=100
    while [ $(pct list | grep -c $ctID ) -eq 1 ]; do
      ctID=$(( $ctID + 1 ))
    done
    ctIP=$(( $(lxc-info $(pct list | awk '{print $1}' | tail -n1) -iH | grep $networkIP | cut -d. -f4) + 1 ))
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
                    --net0 name=eth0,bridge=vmbr0,firewall=1,gw=$gatewayIP,ip=$networkIP.$ctIP/$cidr \
                    --onboot 1 \
                    --force 1 \
                    --unprivileged $unprivileged \
                    --start 1"
  if [ -n "$features" ]; then pctCreateCommand="$pctCreateCommand --features $features"; fi
  pctCreateCommand="$( echo $pctCreateCommand | sed -e 's#                     # #g')"
  pct create $ctID $pctCreateCommand > /dev/null 2>&1
  sleep 5
  if [ $(pct list | grep -cw $containername) -eq 1 ]; then
    echoLOG g "${txt_0904} >> ${wrd_0001}: ${LIGHTPURPLE}$ctID${NOCOLOR}  ${wrd_0002}: ${LIGHTPURPLE}$containername${NOCOLOR}"
    pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1 && apt-get dist-upgrade -y > /dev/null 2>&1"
    if [[ $osType == "debian" ]]; then
      pct exec $ctID -- bash -ci "systemctl stop sshd"
      pct exec $ctID -- bash -ci "sed -i 's+#PermitRootLogin prohibit-password+PermitRootLogin yes+' /etc/ssh/sshd_config > /dev/null 2>&1"
      pct exec $ctID -- bash -ci "systemctl start sshd"
    fi
    # Install Container Standardsoftware
    echoLOG y "${txt_0905}"
    pct exec $ctID -- bash -ci "apt-get install -y curl wget software-properties-common apt-transport-https lsb-core lsb-release gnupg2 net-tools nfs-common cifs-utils > /dev/null 2>&1"
    pct shutdown $ctID --forceStop 1 > /dev/null 2>&1
    sleep 5
    if "$script_path/bin/config_lxc.sh" ${var_language} ${ctID} ${ctIP} "${ctRootpw}" "${containername}"; then
      echoLOG g "${txt_0906}"
    else
      echoLOG r "${txt_0907}"
    fi
  else
    echoLOG r "${txt_0908}"
  fi
}

var_lxcchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0005} " "\n${txt_0909}" 20 80 15 "${lxc_list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

# Check if user input is required, if yes inform user
input=
for choosed_lxc in $var_lxcchoice; do
  source "$script_path/lxc/$choosed_lxc/description.sh"
  if $userinput; then
    if [ -z "$input" ]; then input="$choosed_lxc"; else input="$input, $choosed_lxc"; fi
  fi
done
if [ -n "$input"]; then
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title "${tit_0005}" "\n${txt_0902}: ${input}" 10 80
  echoLOG b "${txt_0902}: ${LIGHTPURPLE}$input${NOCOLOR}"
fi

# start container creation and configuration
for choosed_lxc in $var_lxcchoice; do
  if [ $(pct list | grep -cw "$choosed_lxc") -eq 0 ]; then
    ctRootPW="$(generatePassword 12)"
    create $choosed_lxc $ctRootPW
  else
    echoLOG r "${txt_0910} >> ${wrd_0002}: $choosed_lxc"
  fi
done

exit 0
