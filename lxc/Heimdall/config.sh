#!/bin/bash

pct exec $1 -- bash -ci "apt-get install -y docker.io docker-compose > /dev/null 2>&1"
pct exec $1 -- bash -ci "systemctl start docker && systemctl enable docker > /dev/null 2>&1"
pct exec $1 -- bash -ci "mkdir -p /root/heimdall/"
pct push $1 "$script_path/lxc/heimdall/docker-compose.yml" "/root/heimdall/docker-compose.yml"
pct exec $1 -- bash -ci "sed -i 's#TIMEZONETOCHANGE#'"$timezone"'#' /root/heimdall/docker-compose.yml"
pct exec $1 -- bash -ci "cd /root/heimdall && docker-compose up -d --quiet-pull > /dev/null 2>&1"

exit 0
