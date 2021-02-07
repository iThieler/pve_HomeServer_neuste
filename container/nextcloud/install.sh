#!/bin/bash

# Container Configuration
# $1=ctTemplate (ubuntu/debian/turnkey-openvpn) - $2=hostname - $3=ContainerRootPasswort - $4=hdd size - $5=cpu cores - $6=RAM Swap/2 - $7=unprivileged 0/1 - $8=features (keyctl=1,nesting=1,mount=cifs)
containerSetup ubuntu $ctName $ctRootpw 8 1 4096 0 "mount=cifs;nfs"

# Comes from Mainscript - start.sh --> Function containerSetup
ctID=$?

# Software that must be installed on the container
# example - containerSoftware="docker.io docker-compose"
containerSoftware="apache2 mariadb-server libapache2-mod-php7.4 php7.4-gd php7.4-mysql php7.4-curl php7.4-mbstring php7.4-intl php7.4-gmp php7.4-bcmath php-imagick php7.4-xml php7.4-zip"

# Start Container, because Container stoped aftrer creation
pct start $ctID
sleep 10

# echo [INFO] The container "CONTAINERNAME" is prepared for configuration
echo -e "$info $lng_lxc \"$ctName\" $lng_installlxc1"

# Install the packages specified as containerSoftware
for package in $containerSoftware; do
  # echo [INFO] "PACKAGENAME" will be installed
  echo -e "$info \"$package\" $lng_installlxc"
  pct exec $nextCTID -- bash -c "apt-get install -y $package > /dev/null 2>&1"
done

# Execute commands on containers
pct exec $ctID -- bash -ci "sed -i 's+""memory_limit = 128M""+""memory_limit = 1024M""+g' /etc/php/7.4/apache2/php.ini"
pct exec $ctID -- bash -ci "sed -i 's+""upload_max_filesize = 2M""+""upload_max_filesize = 16G""+g' /etc/php/7.4/apache2/php.ini"
pct exec $ctID -- bash -ci "sed -i 's+""post_max_size = 8M""+""post_max_size = 16G""+g' /etc/php/7.4/apache2/php.ini"
pct exec $ctID -- bash -ci "sed -i 's+"";date.timezone = ""+""date.timezone = Europe/Berlin""+g' /etc/php/7.4/apache2/php.ini"
pct exec $ctID -- bash -ci "wget -qO /root/sql_secure.sh $rawGitHubURL/container/nextcloud/sqlsecure.sh"
pct exec $ctID -- bash -ci "sed -i 's+ROOTPASSWORDTOCHANGE+$ctRootpw+g' /root/sql_secure.sh"
pct exec $ctID -- bash -ci "bash /root/sql_secure.sh"
pct exec $ctID -- bash -ci "rm /root/sql_secure.sh"
pct exec $ctID -- bash -ci "mysql -u root -p$ctRootpw -e ""CREATE DATABASE nextcloud;"" > /dev/null 2>&1" > EOF
pct exec $ctID -- bash -ci "mysql -u root -p$ctRootpw -e ""CREATE USER nextcloud@localhost IDENTIFIED BY '${ctRootpw}';"" > /dev/null 2>&1" > EOF
pct exec $ctID -- bash -ci "mysql -u root -p$ctRootpw -e ""GRANT ALL PRIVILEGES ON nextcloud.* TO nextcloud@localhost;"" > /dev/null 2>&1" > EOF
pct exec $ctID -- bash -ci "mysql -u root -p$ctRootpw -e ""FLUSH PRIVILEGES;"" > /dev/null 2>&1" > EOF
pct exec $ctID -- bash -ci "wget https://download.nextcloud.com/server/releases/latest.zip"
pct exec $ctID -- bash -ci "unzip latest.zip > /dev/null 2>&1"
pct exec $ctID -- bash -ci "mv nextcloud /var/www/ > /dev/null 2>&1"
pct exec $ctID -- bash -ci "rm latest.zip"
pct exec $ctID -- bash -ci "wget -qO /etc/apache2/sites-available/nextcloud.conf $rawGitHubURL/container/nextcloud/nextcloud.conf"
pct exec $ctID -- bash -ci "sed -i 's+EMAILTOCHANGE+$varrootmail+g' /etc/apache2/sites-available/nextcloud.conf > /dev/null 2>&1"
pct exec $ctID -- bash -ci "sed -i 's+SERVERNAMETOCHANGE+cloud.$(hostname -f | cut -d. -f2,3,4,5)+g' /etc/apache2/sites-available/nextcloud.conf > /dev/null 2>&1"
pct exec $ctID -- bash -ci "sed -i 's+SERVERALIESTOCHANGE+cloud.$(echo "$varrootmail" | cut -d\@ -f2)+g' /etc/apache2/sites-available/nextcloud.conf > /dev/null 2>&1"
pct exec $ctID -- bash -ci "a2ensite nextcloud.conf > /dev/null 2>&1 && a2enmod rewrite > /dev/null 2>&1 && a2enmod headers > /dev/null 2>&1 && a2enmod env > /dev/null 2>&1 && a2enmod dir > /dev/null 2>&1 && a2enmod mime > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl restart apache2.service"
pct exec $ctID -- bash -ci "chmod -R 755 /var/www/nextcloud/"
pct exec $ctID -- bash -ci "chown -R www-data:www-data /var/www/nextcloud/"

# If NAS exist in Network, bind to Container, only privileged and mount=cifs Feature is set
if [[ $nasexists == "y" ]]; then
  lxcMountNAS $ctID
fi

# Container description in the Proxmox web interface
pct set $ctID --description $'Shell Login\nBenutzer: root\nPasswort: '"$ctRootpw"$'\n\nWebGUI\nAdresse: https://'"$nextCTIP"

# echo [INFO] Create firewall rules for container "CONTAINERNAME"
echo -e "$info $lng_lxcfw \"$ctName\""

# Creates firewall rules for the container
# Create Firewallgroup - If a port should only be accessible from the local network - IN ACCEPT -source +network -p tcp -dport PORTNUMBER -log nolog
echo -e "[group $(echo $ctName|tr "[:upper:]" "[:lower:]")]\n\nIN HTTPS(ACCEPT) -log nolog # Weboberfläche HTTPs\nIN HTTP(ACCEPT) -source +network -log nolog # Weboberfläche\n\n" >> $clusterfile

# Allow Firewallgroup
echo -e "[OPTIONS]\n\nenable: 1\n\n[RULES]\n\nGROUP $(echo $ctName|tr "[:upper:]" "[:lower:]")" > /etc/pve/firewall/$ctID.fw
