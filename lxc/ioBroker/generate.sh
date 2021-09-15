#!/bin/bash

################### Container Configuration ###################

template=${osUbuntu20_04}
hddsize=16
cpucores=2
memory=2048
swap=2048
unprivileged=0
features="nesting=1,mount=cifs;nfs"

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "WebGUI" "WebGUI (vis)" )
webguiPort=( "8081" "8082" )
webguiPath=( "" "/vis/" )
webguiUser=( "admin" "" )
webguiPass=( "changeme" )
webguiProt=( "http" "http" )

################### Firewall Configuration ####################

fwPort=( "80" "443" "22" "8081" "8082" )
fwNetw=( "network" "" "pnetwork" "network" "pnetwork" )
fwProt=( "tcp" "tcp" "tcp" "tcp" "tcp" )
fwDesc=( "HTTP" "HTTPS" "SSH" "Admin WebGUI" "ioBrokerVIS" )

#################### Needed Hardwarebinds #####################

nasneeded=true
dvbneeded=false
vganeeded=false

####################### Needed Services #######################

fncneeded=false
smtpneeded=false
apparmorProfile="unconfined"
sambaneeded=false
sambaUser=""
smarthomeVLAN=true
guestVLAN=false
