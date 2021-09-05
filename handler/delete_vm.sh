#!/bin/bash

var_language=$1
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

if [ $(qm list | grep -c 2.*) -eq 0 ] ; then
  NEWT_COLORS='
      window=black,red
      border=white,red
      textbox=white,red
      button=black,yellow
    ' \
  whiptail --msgbox --backtitle "© 2021 - SmartHome-IoT.net" --title " XXXXXXXXXX " "\nXXXXXXXXXX" 10 80
  echoLOG r "XXXXXXXXXX"
  exit 1
fi
