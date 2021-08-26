#!/bin/bash

script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

# make list of available Containers, hide already existing
echo "- ${txt_0201}"
available_lxc=$(pct list | awk '{print $1}' | tail +2 | sed ':M;N;$!bM;s#\n# #g')
echo -e "#!/bin/bash\n\nlxc_list=( \\" > /tmp/lxclist.sh
desc="desc_${var_language}"
if [ -n "${!desc}" ]; then desc="desc_en"; fi 
for lxc in $available_lxc; do
  lxc=$(pct list | grep -w ${lxc} | awk '{print $3}')
  source "$script_path/lxc/${lxc}/description.sh"
  echo -e "\"${lxc}\" \""${!desc}  "\" off \\" >> /tmp/lxclist.sh
done
echo -e ")" >> /tmp/lxclist.sh

source /tmp/lxclist.sh

var_lxcchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_6} " "\n${txt_0206}" 20 80 15 "${lxc_list[@]}" 3>&1 1>&2 2>&3 | sed 's#"##g')

for choosed_lxc in $var_lxcchoice; do
  ctID=$(pct list | grep -w "$choosed_lxc" | awk '{print $1}')
  NEWT_COLORS='
    window=black,red
    border=white,red
    textbox=white,red
    button=black,yellow
  ' \
  whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_8} " "\n${txt_0208}\n\n${wrd_7}: ${ctID}\n${wrd_6}: ${choosed_lxc}\n\n${txt_0209}" 15 80
  yesno=$?
  if [ $yesno -eq 0 ]; then
    pct destroy $ctID --force 1 --purge 1 > /dev/null 2>&1
    ##################################################################
    ############# Delete firewall rules of the container #############
    ##################################################################
    sleep 5
    echo -e "- ${txt_0210}:\n  ${wrd_7}: $ctID\n  ${wrd_6}: ${choosed_lxc}"
  fi
done

exit 0
