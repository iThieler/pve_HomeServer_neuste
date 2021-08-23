#!/bin/bash

################### Container Configuration ###################

template=${osUbuntu20_04}
hddsize=8
cpucores=1
memory=2048
swap=2048
unprivileged=0
features="nesting=1,mount=nfs;cifs"

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "WebGUI" )
webguiPort=( "32400" )
webguiPath=( "/web" )
webguiUser=( "" )
webguiPass=( "" )
webguiProt=( "http" )

################### Firewall Configuration ####################

fwPort=( "32400" "1900" "5353" "8324" "32410" "32412:32414" "32469" )
fwNetw=( "" "network" "network" "network" "network" "network" "network" )
fwProt=( "tcp" "udp" "udp" "tcp" "udp" "udp" "tcp" )
fwDesc=( "access to the Plex Media Server" "access to the Plex DLNA Server" "older Bonjour/Avahi network discovery" "controlling Plex for Roku via Plex Companion" "controlling Plex for Roku via Plex Companion" "controlling Plex for Roku via Plex Companion" "access to the Plex DLNA Server" )

#################### Needed Hardwarebinds #####################

nasneeded=true
dvbneeded=false
vganeeded=true

####################### Needed Services #######################

fncneeded=false
smtpneeded=false
apparmorProfile=""
sambaneeded=false
sambaUser=""
