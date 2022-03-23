#!/bin/bash

################### Container Configuration ###################

template=${osUbuntu20_04}
hddsize=16
cpucores=1
memory=512
swap=512
unprivileged=1
features="keyctl=1,nesting=1"

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "WebGUI" )
webguiPort=( "81" )
webguiPath=( "" )
webguiUser=( "admin@example.com" )
webguiPass=( "changeme" )
webguiProt=( "http" )

################### Firewall Configuration ####################

fwPort=( "80" "81" "443" )
fwNetw=( "network" "network" "" )
fwProt=( "tcp" "tcp" "tcp" )
fwDesc=( "NginxProxyManager (HTTP)" "NginxProxyManager (Admin)" "NginxProxyManager (HTTPS)" )

#################### Needed Hardwarebinds #####################

nasneeded=false
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
