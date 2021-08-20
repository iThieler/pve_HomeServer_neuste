#!/bin/bash

pct exec $1 -- bash -ci "wget -q https://github.com/MediaBrowser/Emby.Releases/releases/download/$( githubLatest \"MediaBrowser/Emby.Releases\" )/emby-server-deb_$( githubLatest \"MediaBrowser/Emby.Releases\" )_amd64.deb"
pct exec $1 -- bash -ci "dpkg -i emby-server-deb_*_amd64.deb > /dev/null 2>&1"
pct exec $1 -- bash -ci "rm emby-server-deb_*_amd64.deb"
pct exec $1 -- bash -ci "systemctl start emby-server && systemctl enable emby-server > /dev/null 2>&1"

exit 0
