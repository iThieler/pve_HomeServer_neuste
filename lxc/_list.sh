#!/bin/bash

# These containers do not require a Nas
lxc=( \
  "Heimdall" "App Dashboard" off \
  "ReverseProxy" "NGINX Proxy Manager" off \
  "ExitAccess" "piHole & piVPN" off \
  "iDBGrafana" "influxDB & Grafana" off \
  "ioBroker" "SmartHome - Automate your life" off \
  "3cx" "Phone System " off \
  )

# These containers require a Nas
lxcNAS=( \
  "JellyFin" "Mediaserver" off \
  "emby" "Mediaserver" off \
  "Plex" "Mediaserver" off \
  "Radarr" "" off \
  "Sonarr" "" off \
  "sabNZBd" "NZB Downloader" off \
  "TVHeadend" "Live-TV-Server mit Videorecorder" off \
  "nextCloud" "Ein eigene Cloudserver" off \
  "ecoDMS" "Dokumentenmanagementsystem" off \
)
