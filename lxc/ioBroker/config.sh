#!/bin/bash

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

ctID=$1
ctRootpw=$2
ctIP=$(lxc-info $ctID -iH | grep $networkIP)
containername=$(pct list | grep $ctID | awk '{print $3}')

standardAdapter="parser javascript web vis vis-inventwo vis-icontwo influxdb proxmox"
configFile="cfg_ioBroker.sh"

pct exec $ctID -- bash -ci "curl -sLf https://iobroker.net/install.sh | bash - > /dev/null 2>&1"

todo=(\
          "1" "${lxc_txt_002}" \
          "2" "${lxc_txt_003}" \
          )

gw=(\
  "unifi" "  Ubiquiti/UniFi DreamMachine Pro ${wrd_14} CloudKey" off \
  "avm" "  AVM FRITZ!Box" off \
  "none" "  ${lxc_txt_009}" off \
)

if [ -z "$var_nasip" ]; then pct exec $ctID -- bash -ci "mkdir -p /mnt/backup/$containername/javascript/"; fi

variation=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ioBroker " "\n$lxc_txt_001" 20 80 10 "${todo[@]}" 3>&1 1>&2 2>&3)
if [[ $variation == "1" ]]; then
  gateway=$(whiptail --menu --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ioBroker " "\n$lxc_txt_010" 20 80 10 "${gw[@]}" 3>&1 1>&2 2>&3)
  vislicensecode=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ioBroker " "$lxc_txt_005" 20 80 3>&1 1>&2 2>&3)
  if [ $(pct list | grep -cw \"iDBGrafana\") -eq 0 ]; then
    grafanaPW=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ioBroker " "Wie lautet dein Grafana Passwort? (leer = Skript Standardpasswort)" 20 80 3>&1 1>&2 2>&3)
    if [ -n "$grafanaPW" ]; then grafanaPW="changeme"; fi
    grafana=" --influxDBEnabled true --grafanaEnabled true --grafanaHost $(lxc-info $(pct list | grep iDBGrafana | awk '{print $1}') -iH) --grafanaPassword \"${grafanaPW}\" "
  fi
  if [ -z "$var_nasip" ]; then
    nas=" --cifsEnabled true --cifsMount $var_nasip --cifsUser $var_robotname --cifsPassword $var_robotpw --cifsDir \"/mnt/backup/$containername/\" --javascriptsPath \"/mnt/backup/$containername/javascript/\""
  fi
  pct exec $ctID -- bash -ci "iobroker set backitup.0 --minimalEnabled true --javascriptsEnabled true  --minimalTime \"00:00\" --minimalDeleteAfter \"6\" --select-options-abad7d88-51a8-8592-4f1f-5d1f89c614311 true${nas}${grafana} > /dev/null 2>&1"
  for adp in $standardAdapter; do
    pct exec $ctID -- bash -ci "iobroker add iobroker.$adp > /dev/null 2>&1"
  done
  if [ -z "$var_nasip" ]; then javamirrorpath=" --mirrorPath \"/mnt/backup/$containername/javascript/\""; fi
  pct exec $ctID -- bash -ci "iobroker set javascript.0$javamirrorpath --enableSetObject true --enableExec true --enableSendToHost true > /dev/null 2>&1"
  if [ -z "$vislicensecode" ]; then pct exec $ctID -- bash -ci "iobroker set vis.0 --license "$vislicensecode" > /dev/null 2>&1"; fi
  if [ $(pct list | grep -cw \"iDBGrafana\") -eq 0 ]; then
    pct exec $ctID -- bash -ci "iobroker set influxdb.0 --host $(lxc-info $(pct list | grep iDBGrafana | awk '{print $1}') -iH) --user iobroker --password $ctRootpw --passwordConfirm $ctRootpw --dbname iobroker > /dev/null 2>&1"
  fi
  pct exec $ctID -- bash -ci "iobroker set proxmox.0 --ip $pveIP --name $var_robotname --select-options-225a0870-9529-3d5e-9970-0bbdb092c4d21 true --pwd $var_robotpw > /dev/null 2>&1"
  if [[ $gateway == "avm" ]]; then
    pct exec $ctID -- bash -ci "iobroker add iobroker.fb-checkpresence --enabled > /dev/null 2>&1"
    whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "SmartHome-IoT.net" --title " ioBroker " "$lxc_txt_006" 20 80
    gwnetrobot=$?
    if [[ $gwnetrobot == 0 ]]; then
      pct exec $ctID -- bash -ci "iobroker set fb-checkpresence.0 --ipaddress $gatewayIP --username $var_robotname --password $var_robotpw --select-options-0060129c-6cb9-01e2-39c5-1449a75d940c1 true --dateformat \"dd.mm.yyyy HH:MM\" > /dev/null 2>&1"
    else
      vargwadmin=$(whiptail --inputbox --nocancel --backtitle "SmartHome-IoT.net" --title " ioBroker " "$lxc_txt_007" 20 80 3>&1 1>&2 2>&3)
      vargwadminpw=$(whiptail --inputbox --nocancel --backtitle "SmartHome-IoT.net" --title " ioBroker " "$lxc_txt_008" 20 80 3>&1 1>&2 2>&3)
      pct exec $ctID -- bash -ci "iobroker set fb-checkpresence.0 --ipaddress $gatewayIP --username $vargwadmin --password $vargwadminpw --select-options-0060129c-6cb9-01e2-39c5-1449a75d940c1 true --dateformat \"dd.mm.yyyy HH:MM\" > /dev/null 2>&1"
    fi
  elif [[ $gateway == "unifi" ]]; then
    pct exec $ctID -- bash -ci "iobroker add iobroker.unifi --enabled > /dev/null 2>&1"
    whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "SmartHome-IoT.net" --title " ioBroker " "$lxc_txt_006" 20 80
    yesno=$?
    if [[ $yesno == 0 ]]; then
      pct exec $ctID -- bash -ci "iobroker set unifi.0 --controllerIp $gatewayIP --controllerUsername $var_robotname --controllerPassword $var_robotpw > /dev/null 2>&1"
    else
      vargwadmin=$(whiptail --inputbox --nocancel --backtitle "SmartHome-IoT.net" --title " ioBroker " "$lxc_txt_007" 20 80 3>&1 1>&2 2>&3)
      vargwadminpw=$(whiptail --inputbox --nocancel --backtitle "SmartHome-IoT.net" --title " ioBroker " "$lxc_txt_008" 20 80 3>&1 1>&2 2>&3)
      pct exec $ctID -- bash -ci "iobroker set unifi.0 --controllerIp $gatewayIP --controllerUsername $vargwadmin --controllerPassword $vargwadminpw > /dev/null 2>&1"
    fi
  fi
  if [ -z "$var_nasip" ]; then
    whiptail --yesno --yes-button " ${btn_3} " --no-button " ${btn_4} " --backtitle "SmartHome-IoT.net" --title " ioBroker " "$lxc_txt_011" 20 80
    yesno=$?
    if [[ $yesno == 0 ]]; then
      synology=true
      pct exec $ctID -- bash -ci "iobroker add iobroker.synology --enabled > /dev/null 2>&1"
      pct exec $ctID -- bash -ci "iobroker set synology.0 --host $var_nasip --login $var_robotname --password $var_robotpw --select-options-eaf2de04-a533-e52b-f1f9-4397440daa4718 true > /dev/null 2>&1"
    fi
  fi
  pct exec $ctID -- bash -ci "iobroker passwd admin --password changeme > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "iobroker set admin.0 --auth true > /dev/null 2>&1"
elif [[ $variation == "2" ]]; then
  if [ $(pct list | grep -cw \"iDBGrafana\") -eq 0 ]; then
    grafanaPW=$(whiptail --inputbox --nocancel --backtitle "© 2021 - SmartHome-IoT.net" --title " ioBroker " "Wie lautet dein Grafana Passwort? (leer = Skript Standardpasswort)" 20 80 3>&1 1>&2 2>&3)
    if [ -z "$grafanaPW" ]; then grafanaPW="changeme"; fi
    grafana=" --influxDBEnabled true --grafanaEnabled true --grafanaHost $(lxc-info $(pct list | grep iDBGrafana | awk '{print $1}') -iH) --grafanaPassword \"${grafanaPW}\" "
  fi
  if [ -n "$var_nasip" ]; then
    nas=" --cifsEnabled true --cifsMount $var_nasip --cifsUser $var_robotname --cifsPassword $var_robotpw --cifsDir \"/mnt/backup/$containername/\" --javascriptsPath \"/mnt/backup/$containername/javascript/\""
  fi
  pct exec $ctID -- bash -ci "iobroker set backitup.0 --minimalEnabled true --javascriptsEnabled true  --minimalTime \"00:00\" --minimalDeleteAfter \"6\" --select-options-abad7d88-51a8-8592-4f1f-5d1f89c614311 true${nas}${grafana} > /dev/null 2>&1"

  # create config File
  echo -e "\0043\0041/bin/bash" > $shiot_configPath/$configFile
  echo -e "\0043 NOTICE: Backup ioBroker Configuration Script from SmartHome-IoT.net" >> $shiot_configPath/$configFile
  echo -e "\0043 Created on $(date)" >> $shiot_configPath/$configFile

  echo -e "\n\0043 Network Hardware configuration" >> $shiot_configPath/$configFile
  echo -e "gateway=\"$gateway\"" >> $shiot_configPath/$configFile
  echo -e "synology=\"$synology\"" >> $shiot_configPath/$configFile

  echo -e "\n\0043 User configuration" >> $shiot_configPath/$configFile
  if [[ $gwnetrobot == 0 ]]; then
    echo -e "vargwadmin=\"$var_robotname\"" >> $shiot_configPath/$configFile
    echo -e "vargwadminpw=\"$var_robotpw\"" >> $shiot_configPath/$configFile
  else
    echo -e "vargwadmin=\"$vargwadmin\"" >> $shiot_configPath/$configFile
    echo -e "vargwadminpw=\"$vargwadminpw\"" >> $shiot_configPath/$configFile
  fi
fi

exit 0
