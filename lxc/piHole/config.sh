#!/bin/bash

pct exec $1 -- bash -ci "mkdir -p /etc/pihole/"
pct push $1 "$script_path/lxc/piHole/setupVars.conf" "/etc/pihole/setupVars.conf"
pct exec $1 -- bash -ci "sed -i 's#IPADRESSTOCHANGE#'"$ctIP"'#g' /etc/pihole/setupVars.conf"
pct exec $1 -- bash -ci "sed -i 's#CIDRTOCHANGE#'"$cidr"'#g' /etc/pihole/setupVars.conf"
pct exec $1 -- bash -ci "curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended > /dev/null 2>&1"
pct exec $1 -- bash -ci "/usr/local/bin/pihole -a -p changeme > /dev/null 2>&1"
pct push $1 "$script_path/lxc/piHole/updateAdlist.sh" "/root/updateAdlist.sh"
pct exec $1 -- bash -ci "chmod +x /root/updateAdlist.sh"
pct exec $1 -- bash -ci "bash /root/updateAdlist.sh"
pct exec $1 -- bash -ci "crontab -l | { cat; echo \"0 03 1,14 * *   root    /root/updateAdlist.sh\"; } | crontab -"

exit 0
