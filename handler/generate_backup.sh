#!/bin/bash

var_language=$1
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

# make list of available Containers, hide already existing
echoLOG b "${txt_0701}"
available_lxc=$(pct list | awk '{print $1}' | tail +2 | sed ':M;N;$!bM;s#\n# #g')
available_vm=$(qm list | awk '{print $1}' | tail +2 | sed ':M;N;$!bM;s#\n# #g')
echo -e "#!/bin/bash\n\nguest_list=( \\" > /tmp/guestlist.sh
for lxc in $available_lxc; do
  lxc=$(pct list | grep -w ${lxc} | awk '{print $3}')
  source "$script_path/lxc/${lxc}/description.sh"
  desc="desc_${var_language}"
  if [ -n "${!desc}" ]; then desc="desc_en"; fi
  echo -e "\"${lxc}\" \""${!desc}  "\" off \\" >> /tmp/guestlist.sh
done
for vm in $available_vm; do
  vm=$(qm list | grep -w ${vm} | awk '{print $2}')
  source "$script_path/vm/${vm}/description.sh"
  desc="desc_${var_language}"
  if [ -n "${!desc}" ]; then desc="desc_en"; fi
  echo -e "\"${vm}\" \""${!desc}  "\" off \\" >> /tmp/guestlist.sh
done
echo -e ")" >> /tmp/guestlist.sh

source /tmp/guestlist.sh

var_guestchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0006} " "\n${txt_0702}" 20 80 15 "${guest_list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

for choosed_guest in $var_guestchoice; do
  if [ $(pct list | grep -cw "$choosed_guest") -eq 1 ]; then guestID=$(pct list | grep -w "$choosed_guest" | awk '{print $1}'); fi
  if [ $(qm list | grep -cw "$choosed_guest") -eq 1 ]; then guestID=$(qm list | grep -w $choosed_guest | awk '{print $1}'); fi
  echo b "${txt_0703} >> ${wrd_0001}: $guestID  ${wrd_0002}: ${choosed_guest}"
  vzdump $guestID --compress zstd --exclude-path /mnt/ --exclude-path /media/ --mode snapshot --quiet 1 --maxfiles 6 --storage backups
  if [ $? -eq 0 ]; then echo g "${txt_0704}"; else echo r "${txt_0705}"; fi
done

exit 0
