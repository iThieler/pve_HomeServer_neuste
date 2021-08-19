#!/bin/bash

Commands="pct exec $ctID -- bash -ci \"apt-get install -y docker.io docker-compose > /dev/null 2>&1\"
          pct exec $ctID -- bash -ci \"systemctl start docker && systemctl enable docker > /dev/null 2>&1\"
          pct exec $ctID -- bash -ci \"mkdir -p /root/npm/ > /dev/null 2>&1\"
          pct push $ctIP \"$script_path/lxc/ReverseProxy/docker-compose.yml\" \"/root/npm/docker-compose.yml\"
          pct exec $ctID -- bash -ci \"sed -i 's#ROOTPASSWORDTOCHANGE#'"$ctRootpw"'#g' /root/npm/docker-compose.yml\"
          pct exec $ctID -- bash -ci \"cd /root/npm && docker-compose up -d --quiet-pull > /dev/null 2>&1\""
