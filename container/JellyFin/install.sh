#!/bin/bash

echo -e "[group jellyfin]\n\nIN ACCEPT -p tcp -dport 8920 -log nolog # Weboberfläche HTTPs\nIN ACCEPT -source +network -p tcp -dport 8096 -log nolog # Weboberfläche\nIN ACCEPT -source +network -p udp -dport 7359 -log nolog # Client Discovery\nIN ACCEPT -source +network -p udp -dport 1900 -log nolog # Service Discovery\n\n" >> $fwcluster
