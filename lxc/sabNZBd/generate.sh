#!/bin/bash

################### Container Configuration ###################

template=${osUbuntu20_04}
hddsize=4
cpucores=1
memory=512
swap=512
unprivileged=0
features="mount=cifs"

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "WebGUI" )
webguiPort=( "" )    
webguiPath=( "" )
webguiUser=( "admin" )
webguiPass=( "changeme" )
webguiProt=( "http" )

################### Firewall Configuration ####################

fwPort=( "80" "443" )
fwNetw=( "network" "" "pnetwork" )
fwProt=( "tcp" "tcp" )
fwDesc=( "HTTP" "HTTPS" )

#################### Needed Hardwarebinds #####################

nasneeded=true
dvbneeded=false
vganeeded=false

####################### Needed Services #######################

fncneeded=false
smtpneeded=false
apparmorProfile=""
sambaneeded=false
sambaUser=""
smarthomeVLAN=false
guestVLAN=false
