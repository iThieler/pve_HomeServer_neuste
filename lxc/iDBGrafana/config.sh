#!/bin/bash

ctID=$1
ctIP=$2
ctRootpw="$3"
containername="$4"

source "$script_path/bin/variables.sh"
source "$script_path/handler/global_functions.sh"
source "$shiot_configPath/$shiot_configFile"
source "$script_path/language/$var_language.sh"

pct exec $ctID -- bash -ci "wget -qO - https://repos.influxdata.com/influxdb.key | apt-key add - > /dev/null 2>&1"
pct exec $ctID -- bash -ci "wget -qO - https://packages.grafana.com/gpg.key | apt-key add - > /dev/null 2>&1"
pct exec $ctID -- bash -ci "echo \"deb https://repos.influxdata.com/ubuntu focal stable\" > /etc/apt/sources.list.d/influxdb.list"
pct exec $ctID -- bash -ci "echo \"deb https://packages.grafana.com/oss/deb stable main\" > /etc/apt/sources.list.d/grafana.list"
pct exec $ctID -- bash -ci "apt-get update > /dev/null 2>&1"
pct exec $ctID -- bash -ci "apt-get install -y influxdb grafana > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl unmask influxdb.service && systemctl enable influxdb && systemctl start influxdb"
pct exec $ctID -- bash -ci "mkdir -p /var/lib/grafana/dashboards/"
pct push $ctID "$script_path/lxc/$containername/proxmox.json" "/var/lib/grafana/dashboards/proxmox.json"
pct exec $ctID -- bash -ci "chown grafana:grafana /var/lib/grafana/dashboards/proxmox.json"
pct exec $ctID -- bash -ci "echo -e \"[[udp]]\n enabled = true\n bind-address = \\\":8089\\\"\n database = \\\"proxmox\\\"\n batch-size = 1000\n batch-timeout = \\\"1s\\\"\" >> /etc/influxdb/influxdb.conf"
pct exec $ctID -- bash -ci "sed -i 's+;default_home_dashboard_path =+default_home_dashboard_path = /var/lib/grafana/dashboards/proxmox.json+g' /etc/grafana/grafana.ini"
pct exec $ctID -- bash -ci "sed -n -i '$!N; s/\# enable anonymous access\n\;enabled = false/\# enable anonymous access\n\enabled = true/g;p' /etc/grafana/grafana.ini"
pct exec $ctID -- bash -ci "sed -i 's+;allow_embedding = false+allow_embedding = true+g' /etc/grafana/grafana.ini"
pct exec $ctID -- bash -ci "echo -e \"apiVersion: 1\n\ndatasources:\n  - name: Proxmox\n    type: influxdb\n    url: http://localhost:8086\n    access: proxy\n    database: proxmox\" > /etc/grafana/provisioning/datasources/proxmox.yaml"
pct exec $ctID -- bash -ci "echo -e \"apiVersion: 1\n\nproviders:\n  - name: SmartHome-IoT\n    type: file\n    disableDeletion: true\n    updateIntervalSeconds: 60\n    options:\n      path: /var/lib/grafana/dashboards\n      foldersFromFilesStructure: true\" > /etc/grafana/provisioning/dashboards/proxmox.yaml"
pct exec $ctID -- bash -ci "grafana-cli plugins install grafana-clock-panel > /dev/null 2>&1"
pct exec $ctID -- bash -ci "grafana-cli plugins install natel-discrete-panel > /dev/null 2>&1"
pct exec $ctID -- bash -ci "grafana-cli admin reset-admin-password changeme > /dev/null 2>&1"
pct exec $ctID -- bash -ci "systemctl stop grafana-server"
pct exec $ctID -- bash -ci "rm /var/log/grafana/grafana.log"
pct exec $ctID -- bash -ci "chown grafana:grafana /var/lib/grafana/*"
pct exec $ctID -- bash -ci "systemctl restart influxdb"
pct exec $ctID -- bash -ci "systemctl daemon-reload && systemctl enable grafana-server > /dev/null 2>&1 && systemctl start grafana-server"
echo -e "influxdb: InfluxDB\n          port 8089\n          server $networkIP.$ctIP" > /etc/pve/status.cfg

exit 0
