#!/bin/bash

################### Container Configuration ###################

template=${osUbuntu20_04}
hddsize=8
cpucores=1
memory=256
swap=256
unprivileged=0
features="mount=cifs"
description="${desc_001}"

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "WebGUI" )
webguiPort=( "" )    
webguiPath=( "" )
webguiUser=( "" )
webguiPass=( "" )
webguiProt=( "http" )

################### Firewall Configuration ####################

fwPort=( "80" "443" )
fwNetw=( "network" "pnetwork" )
fwProt=( "tcp" "tcp" )
fwDesc=( "HTTP" "HTTPS" )

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
