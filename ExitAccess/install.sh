#!/bin/bash

echo -e "[group adblocker]\n\nIN ACCEPT -source +network -p tcp -dport 4711 -log nolog # API\nIN ACCEPT -source +network -p udp -dport 67 -log nolog # DHCP\nIN ACCEPT -source +network -p tcp -dport 67 -log nolog # DHCP\nIN ACCEPT -source +network -p udp -dport 53 -log nolog # DNS\nIN ACCEPT -source +network -p tcp -dport 53 -log nolog # DNS\nIN HTTP(ACCEPT) -source +network -log nolog # Weboberfläche\n\n" >> $fwcluster
echo -e "[group openvpn]\n\nIN ACCEPT -p udp -dport 1194 -log nolog # VPN Tunnel\nIN HTTPS(ACCEPT) -source +network -log nolog # Weboberfläche HTTPs\n\n" >> $fwcluster
