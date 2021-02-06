#!/bin/bash

echo -e "[group idbgrafana]\n\nIN ACCEPT -source +network -p tcp -dport 3000 -log nolog # Grafana Weboberfläche\nIN ACCEPT -source +network -p tcp -dport 8091 -log nolog # Meta nodes\nIN ACCEPT -source +network -p udp -dport 8089 -log nolog # Proxmox Verbindung\nIN ACCEPT -source +network -p tcp -dport 8089 -log nolog # Meta nodes\nIN ACCEPT -source +network -p tcp -dport 8088 -log nolog # other data nodes\nIN ACCEPT -source +network -p tcp -dport 8086 -log nolog # InfluxDB HTTP service\n\n" >> $fwcluster
