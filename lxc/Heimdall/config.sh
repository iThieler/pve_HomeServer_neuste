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

pct exec $ctID -- bash -ci "add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get -y install git apache2 sqlite php7.3 libapache2-mod-php7.3 php7.3-mbstring php7.3-xml php7.3-common php7.3-sqlite3 php7.3-zip > /dev/null 2>&1"
pct exec $ctID -- bash -ci "a2enmod rewrite > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl restart apache2"
pct exec $ctID -- bash -ci "mkdir -p /var/www/heimdall"
pct exec $ctID -- bash -ci "git clone https://github.com/linuxserver/Heimdall.git /var/www/heimdall > /dev/null 2>&1"
pct exec $ctID -- bash -ci "chown -R www-data:www-data /var/www/heimdall"
pct exec $ctID -- bash -ci "chmod -R 755 /var/www/heimdall"
pct exec $ctID -- bash -ci "rm /etc/apache2/sites-enabled/000-default.conf"
pct push $ctID "$script_path/lxc/$containername/apache_conf.txt" "/etc/apache2/sites-enabled/000-default.conf"
pct exec $ctID -- bash -ci "systemctl restart apache2"
pct exec $ctID -- bash -ci "rm /var/www/heimdall/public/img/bg1.jpg"
pct push $ctID "$script_path/images/shiot_wallpaper_1920x1080.jpg" "/var/www/heimdall/public/img/bg1.jpg"

exit 0
