#!/bin/bash

################### Container Configuration ###################

template=${osUbuntu20_04}
hddsize=4
cpucores=1
memory=256
swap=256
unprivileged=1
features="keyctl=1,nesting=1"
description="${desc_001}"

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "WebGUI" "WebGUI (secure)" )
webguiPort=( "" "" )
webguiPath=( "" "" )
webguiUser=( "" "" )
webguiPass=( "" "" )
webguiProt=( "http" "https" )

################### Firewall Configuration ####################

fwPort=( "80" "443" )
fwNetw=( "network" "" )
fwProt=( "tcp" "tcp" )
fwDesc=( "HTTP" "HTTPS" )

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
