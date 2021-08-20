#!/bin/bash

pct exec $1 -- bash -ci "wget -qO - https://repos.influxdata.com/influxdb.key | apt-key add - > /dev/null 2>&1"
pct exec $1 -- bash -ci "wget -qO - https://packages.grafana.com/gpg.key | apt-key add - > /dev/null 2>&1"
pct exec $1 -- bash -ci "echo \"deb https://repos.influxdata.com/debian buster stable\" > /etc/apt/sources.list.d/influxdb.list"
pct exec $1 -- bash -ci "echo \"deb https://packages.grafana.com/oss/deb stable main\" > /etc/apt/sources.list.d/grafana.list"
pct exec $1 -- bash -ci "apt-get install -y influxdb grafana > /dev/null 2>&1"
pct exec $1 -- bash -ci "mkdir -p /var/lib/grafana/dashboards/"
pct push $1 "$script_path/lxc/iDBGrafana/proxmox.json" "/var/lib/grafana/dashboards/proxmox.json"
pct exec $1 -- bash -ci "chown grafana:grafana /var/lib/grafana/dashboards/proxmox.json"
pct exec $1 -- bash -ci "echo -e \"[[udp]]\n enabled = true\n bind-address = \"0.0.0.0:8089\"\n database = \"proxmox\"\n batch-size = 1000\n batch-timeout = \"1s\" >> /etc/influxdb/influxdb.conf"
pct exec $1 -- bash -ci "sed -i 's+;default_home_dashboard_path =+default_home_dashboard_path = /var/lib/grafana/dashboards/proxmox.json+g' /etc/grafana/grafana.ini"
pct exec $1 -- bash -ci "sed -n -i '$!N; s/\# enable anonymous access\n\;enabled = false/\# enable anonymous access\n\enabled = true/g;p' /etc/grafana/grafana.ini"
pct exec $1 -- bash -ci "sed -i 's+;allow_embedding = false+allow_embedding = true+g' /etc/grafana/grafana.ini"
pct exec $1 -- bash -ci "echo -e \"apiVersion: 1\n\ndatasources:\n  - name: Proxmox\n    type: influxdb\n    url: http://localhost:8086\n    access: proxy\n    database: proxmox\" > /etc/grafana/provisioning/datasources/proxmox.yaml"
pct exec $1 -- bash -ci "echo -e \"apiVersion: 1\n\nproviders:\n  - name: SmartHome-IoT\n    type: file\n    disableDeletion: true\n    updateIntervalSeconds: 60\n    options:\n      path: /var/lib/grafana/dashboards\n      foldersFromFilesStructure: true\" > /etc/grafana/provisioning/dashboards/proxmox.yaml"
pct exec $1 -- bash -ci "grafana-cli plugins install grafana-clock-panel > /dev/null 2>&1"
pct exec $1 -- bash -ci "grafana-cli plugins install natel-discrete-panel > /dev/null 2>&1"
pct exec $1 -- bash -ci "grafana-cli admin reset-admin-password changeme > /dev/null 2>&1"
pct exec $1 -- bash -ci "systemctl stop grafana-server"
pct exec $1 -- bash -ci "rm /var/log/grafana/grafana.log"
pct exec $1 -- bash -ci "chown grafana:grafana /var/lib/grafana/*"
pct exec $1 -- bash -ci "systemctl unmask influxdb.service && systemctl start influxdb"
pct exec $1 -- bash -ci "systemctl daemon-reload && systemctl enable grafana-server > /dev/null 2>&1 && systemctl start grafana-server"
echo -e "influxdb: InfluxDB\n        port 8089\n        server $2" > /etc/pve/status.cfg

exit 0
