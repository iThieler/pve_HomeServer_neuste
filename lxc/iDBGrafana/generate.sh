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
webguiName=( "WebGUI (Grafana)" )
webguiPort=( "3000" )
webguiPath=( "" )
webguiUser=( "admin" )
webguiPass=( "changeme" )
webguiProt=( "http" )

################### Firewall Configuration ####################

fwPort=( "8086" "8088" "8089" "3000" )
fwNetw=( "network" "network" "network" "pnetwork" )
fwProt=( "tcp" "tcp" "udp" "tcp" )
fwDesc=( "influxDB HTTP (API)" "influxDB (RPC)" "influxDB (UDP)" "Grafana (HTTP)" )

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
