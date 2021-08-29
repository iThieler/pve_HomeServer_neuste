#!/bin/bash

ctID=$1
ctIP=$2
ctRootpw="$3"
containername="$4"
script_path=$(realpath "$0" | sed 's|\(.*\)/.*|\1|' | cut -d/ -f1,2,3)

source "$script_path/helper/variables.sh"
source "$script_path/helper/functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

pct exec $ctID -- bash -ci "apt-get install -y docker.io docker-compose > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl start docker && systemctl enable docker > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mkdir -p /root/heimdall/"
pct push $ctID "$script_path/lxc/$containername/docker-compose.yml" "/root/heimdall/docker-compose.yml"
pct exec $ctID -- bash -ci "sed -i 's#TIMEZONETOCHANGE#'"$timezone"'#' /root/heimdall/docker-compose.yml"
pct exec $ctID -- bash -ci "cd /root/heimdall && docker-compose up -d --quiet-pull > /dev/null 2>&1"
pct exec $ctID -- bash -ci "rm /root/heimdall/heimdall/www/img/bg1.jpg"
if [ -f "$script_path/images/${var_language}_shiot_wallpaper_1920x1080.jpg"]; then
  pct push $ctID "$script_path/images/${var_language}_shiot_wallpaper_1920x1080.jpg" "/root/heimdall/heimdall/www/img/bg1.jpg"
else
  pct push $ctID "$script_path/images/en_shiot_wallpaper_1920x1080.jpg" "/root/heimdall/heimdall/www/img/bg1.jpg"
fi

exit 0
