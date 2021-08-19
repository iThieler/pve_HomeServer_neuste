#!/bin/bash

################### Container Configuration ###################

template=${osUbuntu20_04}
hddsize=4
cpucores=1
memory=512
swap=512
unprivileged=1
features=""
description="${desc_001}"

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "WebGUI" )
webguiPort=( "" )
webguiPath=( "/admin" )
webguiUser=( "" )
webguiPass=( "changeme" )
webguiProt=( "http" )

################### Firewall Configuration ####################

fwPort=( "53" "53" "67" "547" "80" "4711" )
fwNetw=( "pnetwork" "pnetwork" "pnetwork" "pnetwork" "network" "network" )
fwProt=( "tcp" "udp" "udp" "udp" "tcp" )
fwDesc=( "piHole-FTL (DNS)" "piHole-FTL (DNS)" "piHole-FTL (DHCPv4)" "piHole-FTL (DHCPv6)" "piHole (HTTP)" "piHole-FTL (API)" )

#################### Needed Hardwarebinds #####################

nasneeded=false
dvbneeded=false
vganeeded=false

####################### Needed Services #######################

fncneeded=true
smtpneeded=false
apparmorProfile=""
sambaneeded=false
sambaUser=""
