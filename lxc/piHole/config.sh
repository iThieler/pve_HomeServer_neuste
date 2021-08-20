#!/bin/bash

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"
source "$script_path/lxc/$containername/language/$var_language.sh"

ctID=$1
ctRootpw=$2
ctIP=$(lxc-info $ctID -iH | grep $networkIP)
containername=$(pct list | grep 100 | awk '{print $3}')

pct exec $ctID -- bash -ci "mkdir -p /etc/pihole/"
pct push $ctID "$script_path/lxc/piHole/setupVars.conf" "/etc/pihole/setupVars.conf"
pct exec $ctID -- bash -ci "sed -i 's#IPADRESSTOCHANGE#'"$ctIP"'#g' /etc/pihole/setupVars.conf"
pct exec $ctID -- bash -ci "sed -i 's#CIDRTOCHANGE#'"$cidr"'#g' /etc/pihole/setupVars.conf"
pct exec $ctID -- bash -ci "curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended > /dev/null 2>&1"
pct exec $ctID -- bash -ci "/usr/local/bin/pihole -a -p changeme > /dev/null 2>&1"
pct push $ctID "$script_path/lxc/piHole/updateAdlist.sh" "/root/updateAdlist.sh"
pct exec $ctID -- bash -ci "chmod +x /root/updateAdlist.sh"
pct exec $ctID -- bash -ci "bash /root/updateAdlist.sh"
pct exec $ctID -- bash -ci "crontab -l | { cat; echo \"0 03 1,14 * *   root    /root/updateAdlist.sh\"; } | crontab -"

exit 0
