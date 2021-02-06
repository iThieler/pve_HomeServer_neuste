#!/bin/bash

echo -e "[group telefon] # 3cx\n\nIN ACCEPT -p tcp -dport 5015 -log nolog # Weboberfläche zur Ersteinrichtung\nIN ACCEPT -p tcp -dport 5001 -log nolog # Weboberfläche HTTPs\nIN ACCEPT -p udp -dport 5062 -log nolog # SIP\nIN ACCEPT -p tcp -dport 5062 -log nolog # SIP\nIN ACCEPT -p tcp -dport 5063 -log nolog # secure SIP\nIN ACCEPT -p udp -dport 5090 -log nolog # Tunnel\nIN ACCEPT -p tcp -dport 5090 -log nolog # Tunnel\nIN ACCEPT -p udp -dport 9000:10999 -log nolog # RTP\n\n" >> $fwcluster
