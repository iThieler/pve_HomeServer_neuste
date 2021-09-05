#!/bin/bash

var_language=$1
backupmode=$2
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

if ls /mnt/pve/backups/dump/*_manual.*.zst 1> /dev/null 2>&1; then
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0008} " "\n${txt_1101}" 10 80
  rm /mnt/pve/backups/dump/*_manual*
fi

if [[ $backupmode == "all" ]]; then
  echoLOG y "${txt_1102}"
  echoLOG b "${txt_1103}"
  for lxc in $(pct list | sed '1d' | awk '{print $1}'); do
    echoLOG y "${txt_1104} >> ${wrd_0001}: ${LIGHTPURPLE}$lxc${NOCOLOR}  ${wrd_0002}: ${LIGHTPURPLE}$(pct list | grep $lxc | awk '{print $3}')${NOCOLOR}"
    echoLOG b "${txt_1105}"
    pct shutdown ${lxc} --forceStop 1 --timeout 10 > /dev/null 2>&1
    if vzdump ${lxc} --dumpdir /mnt/pve/backups/dump --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
      filename=$(ls -ldst /mnt/pve/backups/dump/*-${lxc}-*.tar.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
      mv ${filename}.tar.zst ${filename}_manual.tar.zst
      mv ${filename}.log ${filename}_manual.log
      echo "${txt_1108} SmartHome-IoT.net" > ${filename}_manual.tar.zst.notes
      echoLOG g "${txt_1106}"
    else
      echoLOG r "${txt_1107}"
    fi
    pct start ${lxc} > /dev/null 2>&1
  done
  for vm in $(qm list | sed '1d' | awk '{print $1}'); do
    echoLOG y "${txt_1104} >> ${wrd_0001}: ${LIGHTPURPLE}$vm${NOCOLOR}  ${wrd_0002}: ${LIGHTPURPLE}$(qm list | grep $vm | awk '{print $2}')${NOCOLOR}"
    echoLOG b "${txt_1105}"
    qm shutdown ${vm} --forceStop 1 --timeout 30 > /dev/null 2>&1
    if vzdump ${vm} --dumpdir /mnt/pve/backups/dump --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
      filename=$(ls -ldst /mnt/pve/backups/dump/*-${vm}-*.vma.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
      mv ${filename}.vma.zst ${filename}_manual.vma.zst
      mv ${filename}.log ${filename}_manual.log
      echo "${txt_1108}  SmartHome-IoT.net" > ${filename}_manual.vma.zst.notes
      echoLOG g "${txt_1106}"
    else
      echoLOG r "${txt_1107}"
    fi
    qm start ${vm} > /dev/null 2>&1
  done
else
  echo -e '#!/bin/bash\n\nlist=( \\' > /tmp/list.sh
  for lxc in $(pct list | sed '1d' | awk '{print $1}'); do
    echo -e "\"${lxc}\" \""CT - $(pct list | grep ${lxc} | awk '{print $3}')"\" off \\" >> /tmp/list.sh
  done
  for vm in $(qm list | sed '1d' | awk '{print $1}'); do
    echo -e "\"${vm}\" \""VM - $(qm list | grep ${vm} | awk '{print $2}')"\" off \\" >> /tmp/list.sh
  done
  echo -e ')' >> /tmp/list.sh

  source /tmp/list.sh

  var_guestchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0008} " "\nWelche Gastsysteme möchtest du sichern?" 20 35 15 "${list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

  for choosed_guest in $var_guestchoice; do
    echoLOG y "${txt_1104} >> ${wrd_0001}: ${LIGHTPURPLE}$choosed_guest${NOCOLOR}  ${wrd_0002}: ${LIGHTPURPLE}$(cat /tmp/list.sh | grep $choosed_guest | awk '{print $2}')${NOCOLOR}"
    echoLOG b "${txt_1105}"
    if [ $(pct list | grep -c $choosed_guest) -eq 1 ]; then
      pct shutdown ${choosed_guest} --forceStop 1 --timeout 10 > /dev/null 2>&1
    elif [ $(qm list | grep -c $choosed_guest) -eq 1 ]; then
      qm shutdown ${choosed_guest} --forceStop 1 --timeout 30 > /dev/null 2>&1
    fi
    if vzdump ${choosed_guest} --dumpdir /mnt/pve/backups/dump --mode stop --compress zstd --exclude-path /mnt/ --exclude-path /media/ --quiet 1; then
      filename=$(ls -ldst /mnt/pve/backups/dump/*-${choosed_guest}-*.*.zst | awk '{print $10}' | cut -d. -f1 | head -n1)
      if [ -f "${filename}.tar.zst" ]; then
        mv ${filename}.tar.zst ${filename}_manual.tar.zst
      echo "${txt_1108}  SmartHome-IoT.net" > ${filename}_manual.tar.zst.notes
      else
        mv ${filename}.vma.zst ${filename}_manual.vma.zst
      echo "${txt_1108}  SmartHome-IoT.net" > ${filename}_manual.vma.zst.notes
      fi
      mv ${filename}.log ${filename}_manual.log
      echoLOG g "${txt_1106}"
    else
      echoLOG r "${txt_1107}"
    fi
    if [ $(pct list | grep -c $choosed_guest) -eq 1 ]; then
      pct start ${choosed_guest} > /dev/null 2>&1
    elif [ $(qm list | grep -c $choosed_guest) -eq 1 ]; then
      qm start ${choosed_guest} > /dev/null 2>&1
    fi
  done
  rm /tmp/list.sh
fi

if [ $(cat /opt/smarthome-iot_net/shiot_log.txt | grep -cw "${txt_1107}") -eq 0 ]; then exit 0; else exit 1; fi
