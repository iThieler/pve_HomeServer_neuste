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
webguiName=( "WebGUI" "WebGUI (HTTPS)" )
webguiPort=( "8096" "8920" )
webguiPath=( "" "" )
webguiUser=( "" "" )
webguiPass=( "" "" )
webguiProt=( "http" "https" )

################### Firewall Configuration ####################

fwPort=( "1900" "7359" "8096" "8920" )
fwNetw=( "network" "network" "pnetwork" "" )
fwProt=( "udp" "udp" "tcp" "tcp" )
fwDesc=( "service auto-discovery (DLNA)" "auto-discovery (MediaServer)" "WebGUI (HTTP)" "WebGUI (HTTPS)" )

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
smarthomeVLAN=false
guestVLAN=false
