#!/bin/bash

Commands="pct exec $ctID -- bash -ci \"mkdir -p /etc/pihole/\"
          pct push $ctIP \"$script_path/lxc/piHole/setupVars.conf\" \"/etc/pihole/setupVars.conf\"
          pct exec $ctID -- bash -ci \"sed -i 's#IPADRESSTOCHANGE#'"$ctIP"'#g' /etc/pihole/setupVars.conf\"
          pct exec $ctID -- bash -ci \"sed -i 's#CIDRTOCHANGE#'"$cidr"'#g' /etc/pihole/setupVars.conf\"
          pct exec $ctID -- bash -ci \"curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended > /dev/null 2>&1\"
          pct exec $ctID -- bash -ci \"/usr/local/bin/pihole -a -p changeme > /dev/null 2>&1\"
          pct push $ctIP \"$script_path/lxc/piHole/updateAdlist.sh\" \"/root/updateAdlist.sh\"
          pct exec $ctID -- bash -ci \"chmod +x /root/updateAdlist.sh\"
          pct exec $ctID -- bash -ci \"bash /root/updateAdlist.sh\"
          pct exec $ctID -- bash -ci \"crontab -l | { cat; echo \"0 03 1,14 * *   root    /root/updateAdlist.sh\"; } | crontab -\""
