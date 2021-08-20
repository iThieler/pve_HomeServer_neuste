#!/bin/bash

pct exec $1 -- bash -ci "wget -q https://downloads.plex.tv/plex-keys/PlexSign.key -O - | apt-key add - > /dev/null 2>&1"
pct exec $1 -- bash -ci "echo \"deb https://downloads.plex.tv/repo/deb/ public main\" | tee /etc/apt/sources.list.d/plexmediaserver.list > /dev/null 2>&1"
pct exec $1 -- bash -ci "apt-get install -y plexmediaserver > /dev/null 2>&1"
pct exec $1 -- bash -ci "mkdir -p /media/Movies/ > /dev/null 2>&1"
pct exec $1 -- bash -ci "mkdir -p /media/Series/ > /dev/null 2>&1"
pct exec $1 -- bash -ci "mkdir -p /media/Photos/ > /dev/null 2>&1"
pct exec $1 -- bash -ci "systemctl start plexmediaserver && systemctl enable plexmediaserver > /dev/null 2>&1"
pct exec $1 -- bash -ci "sed -i 's+# deb+deb+' /etc/apt/sources.list.d/plexmediaserver.list"

exit 0
