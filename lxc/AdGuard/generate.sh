#!/bin/bash

################### Container Configuration ###################

template=${osUbuntu20_04}
hddsize=4
cpucores=1
memory=512
swap=512
unprivileged=1
features=""

#################### WebGUI Configuration #####################

webgui=true
webguiName=( "WebGUI" "WebGUI ($(echo ${wrd_0018}))" )
webguiPort=( "" "3000" )
webguiPath=( "" )
webguiUser=( "" )
webguiPass=( "" )
webguiProt=( "http" "http" )

################### Firewall Configuration ####################

fwPort=( "53" "53" "67" "68" "68" "80" "443" "443" "3000" "853" "784" "853" "8853" "5443" "5443")
fwNetw=( "pnetwork" "pnetwork" "pnetwork" "pnetwork" "pnetwork" "network" "pnetwork" "pnetwork" "network" "pnetwork" "pnetwork" "pnetwork" "pnetwork" "pnetwork" "pnetwork")
fwProt=( "tcp" "udp" "udp" "tcp" "udp" "tcp" "tcp" "udp" "tcp" "tcp" "udp" "udp" "udp" "tcp" "udp")
fwDesc=( "plain DNS" "plain DNS" "use AdGuard Home as a DHCP server" "use AdGuard Home as a DHCP server" "use AdGuard Home as a DHCP server" "use AdGuard Home's admin panel as well as run AdGuard Home as an HTTPS/DNS-over-HTTPS server" "use AdGuard Home's admin panel as well as run AdGuard Home as an HTTPS/DNS-over-HTTPS server" "use AdGuard Home's admin panel as well as run AdGuard Home as an HTTPS/DNS-over-HTTPS server" "use AdGuard Home's admin panel as well as run AdGuard Home as an HTTPS/DNS-over-HTTPS server" "run AdGuard Home as a DNS-over-TLS server" "run AdGuard Home as a DNS-over-QUIC server" "run AdGuard Home as a DNS-over-QUIC server" "run AdGuard Home as a DNS-over-QUIC server" "run AdGuard Home as a DNSCrypt server" "run AdGuard Home as a DNSCrypt server")

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
