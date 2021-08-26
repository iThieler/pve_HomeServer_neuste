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

pct exec $ctID -- bash -ci "mkdir -p /etc/pihole/"
pct push $ctID "$script_path/lxc/$containername/setupVars.conf" "/etc/pihole/setupVars.conf"
pct exec $ctID -- bash -ci "sed -i 's#IPADRESSTOCHANGE#'"$networkIP"'.'"$ctIP"'#g' /etc/pihole/setupVars.conf"
pct exec $ctID -- bash -ci "sed -i 's#CIDRTOCHANGE#'"$cidr"'#g' /etc/pihole/setupVars.conf"
pct exec $ctID -- bash -ci "curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended > /dev/null 2>&1"
pct exec $ctID -- bash -ci "/usr/local/bin/pihole -a -p changeme > /dev/null 2>&1"
pct push $ctID "$script_path/lxc/$containername/updateAdlist.sh" "/root/updateAdlist.sh"
pct exec $ctID -- bash -ci "chmod +x /root/updateAdlist.sh"
pct exec $ctID -- bash -ci "bash /root/updateAdlist.sh > /dev/null 2>&1"
pct exec $ctID -- bash -ci "crontab -l | { cat; echo \"0 03 1,14 * *   root    /root/updateAdlist.sh\"; } | crontab - > /dev/null 2>&1"

exit 0
