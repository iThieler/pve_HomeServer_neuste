#!/bin/bash

pct exec $1 -- bash -ci "add-apt-repository universe"
pct exec $1 -- bash -ci "wget -O - https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | apt-key add - > /dev/null 2>&1"
pct exec $1 -- bash -ci "echo \"deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/ubuntu $( lsb_release -c -s ) main\" | tee /etc/apt/sources.list.d/jellyfin.list > /dev/null 2>&1"
pct exec $1 -- bash -ci "apt-get install -y jellyfin > /dev/null 2>&1"
pct exec $1 -- bash -ci "mkdir -p /media/Movies/"
pct exec $1 -- bash -ci "mkdir -p /media/Series/"
pct exec $1 -- bash -ci "mkdir -p /media/Photos/"
pct exec $1 -- bash -ci "systemctl start jellyfin && systemctl enable jellyfin > /dev/null 2>&1"

exit 0
