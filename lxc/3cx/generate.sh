#!/bin/bash

################### Container Configuration ###################

template=${osDebian9}
hddsize=32
cpucores=1
memory=1024
swap=1024
unprivileged=0
features="mount=cifs;nfs"

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "WebGUI ($(echo ${wrd_16}))" "WebGUI ($(echo ${wrd_8}))" "WebGUI ($(echo ${wrd_15}))" )
webguiPort=( "5001" "5001/webclient" "5015?v=2" )
webguiPath=( "" "" "" )
webguiUser=( "" "Extension" "" )
webguiPass=( "" "$(echo ${desc_1})" "" )
webguiProt=( "http" "http" "http" )

################### Firewall Configuration ####################

fwPort=( "5015" "5001" "5062" "5062" "5063" "5090" "5090" "9000:10999" )
fwNetw=( "network" "pnetwork" "" "" "" "" "" "" )
fwProt=( "tcp" "tcp" "udp" "tcp" "tcp" "udp" "tcp" "udp" )
fwDesc=( "Web interface for initial setup" "Web GUI" "SIP" "SIP" "secure SIP" "Tunnel" "Tunnel" "RTP" )

#################### Needed Hardwarebinds #####################

nasneeded=false
dvbneeded=false
vganeeded=false

####################### Needed Services #######################

smtpneeded=false
apparmorProfile=""
sambaneeded=false
sambaUser=""
