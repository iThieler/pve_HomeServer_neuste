#!/bin/bash

################### Container Configuration ###################

template=${osDebian9}
hddsize=32
cpucores=1
memory=1024
swap=1024
unprivileged=0
features="mount=cifs;nfs"
description="${desc_001}"

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "WebGUI (Admin)" "WebGUI ($(echo ${wrd_8}))" "WebGUI ($(echo ${desc_002}))" )
webguiPort=( "5001" "5001/webclient" "5015?v=2" )
webguiPath=( "" "" "" )
webguiUser=( "" "$(echo ${desc_003})" "" )
webguiPass=( "" "$(echo ${desc_004})" "" )
webguiProt=( "http" "http" "http" )

################### Firewall Configuration ####################

fwPort=( "5015" "5001" "5062" "5062" "5063" "5090" "5090" "9000:10999" )
fwNetw=( "network" "pnetwork" "" "" "" "" "" "" )
fwProt=( "tcp" "tcp" "udp" "tcp" "tcp" "udp" "tcp" "udp" )
fwDesc=( "${fw_001}" "${fw_002}" "${fw_003}" "${fw_003}" "${fw_004}" "${fw_005}" "${fw_005}" "${fw_006}" )

#################### Needed Hardwarebinds #####################

nasneeded=false
dvbneeded=false
vganeeded=false

####################### Needed Services #######################

smtpneeded=false
apparmorProfile=""
sambaneeded=false
sambaUser=""
