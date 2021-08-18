#!/bin/bash

################### Container Configuration ###################

template=
hddsize=
cpucores=
memory=
swap=
unprivileged=
features=""
description=""

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "" "" "" )
webguiPort=( "" "" "" )
webguiPath=( "" "" "" )
webguiUser=( "" "" "" )
webguiPass=( "" "" "" )
webguiProt=( "" "" "" )

################### Firewall Configuration ####################

fwPort=( "" "" "" )
fwNetw=( "" "" "" )
fwProt=( "" "" "" )
fwDesc=( "" "" "" )

#################### Needed Hardwarebinds #####################

nasneeded=false
dvbneeded=false
vganeeded=false

####################### Needed Services #######################

smtpneeded=false
apparmorProfile=""
sambaneeded=false
sambaUser=""
