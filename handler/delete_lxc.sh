#!/bin/bash

var_language=$1
var_lxcchoice=$2
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

if [ $(pct list | grep -c 1.*) -eq 0 ] ; then
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0008} " "\n${txt_0506}" 10 80
  echoLOG r "${txt_0506}"
  exit 1
fi

# make list of available Containers, hide already existing
echoLOG b "${txt_0501}"
available_lxc=$(pct list | awk '{print $1}' | tail +2 | sed ':M;N;$!bM;s|\n| |g')
echo -e "#!/bin/bash\n\nlxc_list=( \\" > /tmp/lxclist.sh
for lxc in $available_lxc; do
  lxc=$(pct list | grep -w ${lxc} | awk '{print $3}')
  source "$script_path/lxc/$(echo ${lxc} | sed "s|-${wrd_0021}||g")/description.sh"
  desc="desc_${var_language}"
  if [ -n "${!desc}" ]; then desc="desc_en"; fi 
  echo -e "\"${lxc}\" \""${!desc}  "\" off \\" >> /tmp/lxclist.sh
done
echo -e ")" >> /tmp/lxclist.sh

source /tmp/lxclist.sh

if [ -z "$var_lxcchoice" ]; then
  var_lxcchoice=$(whiptail --checklist --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0005} " "\n${txt_0502}" 20 80 15 "${lxc_list[@]}" 3>&1 1>&2 2>&3 | sed 's|"||g')
fi

for choosed_lxc in $var_lxcchoice; do
  ctID=$(pct list | grep -w "$choosed_lxc" | awk '{print $1}')
  NEWT_COLORS='
    window=black,red
    border=white,red
    textbox=white,red
    button=black,yellow
  ' \
  whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "© 2021 - SmartHome-IoT.net" --title " ${tit_0005} " "\n${txt_0503}\n\n${wrd_0001}: ${ctID}\n${wrd_0002}: ${choosed_lxc}\n\n${txt_0504}" 15 80
  yesno=$?
  if [ $yesno -eq 0 ]; then
    pct shutdown $ctID --forceStop 1 --timeout 10 > /dev/null 2>&1
    pct destroy $ctID --force 1 --purge 1 > /dev/null 2>&1
    ##################################################################
    ############# Delete firewall rules of the container #############
    ##################################################################
    sleep 5
    echoLOG g "${txt_0505} >> ${wrd_0001}: $ctID  ${wrd_0002}: ${choosed_lxc}"
  fi
done

exit 0
