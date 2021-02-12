<!-- markdownlint-configure-file { "MD004": { "style": "consistent" } } -->
<!-- markdownlint-disable MD033 -->
<p align="center">
    <a href="https://smarthome-iot.net/">
        <img src="https://avatars.githubusercontent.com/u/39486895?s=460&u=9535216fe331e8c63d6be8c7410448c4999def32&v=4">
    </a>
    <br>
    <strong>Proxmox Konfigurationsskript</strong>
</p>
<!-- markdownlint-enable MD033 -->

#

Proxmox Konfigurationsskript

## ÜBER
Besuchen Sie die [SmartHome-IoT](https://www.smarthome-iot.net) Webseite für weitere Informationen. Dies ist eine Reihe von Shell-Skripten, die dazu dienen, Ihren Homeserver auf einfache Weise in einen konfigurierten „sicheren“ Homeserver zu verwandeln. Während der Konfiguration werden in einem neu installierten [Proxmox]( https://www.proxmox.com/de/proxmox-ve/erste-schritte)-System folgende Konfigurationen angewendet:
- Setzen des Community Repository’s (pve-no-subscription)
- Update des kompletten Systems
- Installation der Softwarepakete (parted, smartmontools, libsasl2-modules)
- Konfiguration der richtigen E-Mailsettings (postfix)
- Konfiguration der S.M.A.R.T.-Benachrichtigungen für das Systemlaufwerk, sowie eine weitere SSD (sofern vorhanden)
- Konfiguration einer weiteren SSD (sofern vorhanden) als Laufwerk für VM Disks, CT Volumes, ISO Images und CT Templates
- Einbindung einer NAS (sofern vorhanden) in Proxmox und Konfiguration als Backuplaufwerk
- Konfiguration der Proxmox Firewall
- Bereitstellen von verschiedenen zu Auswahl stehenden Containern, unter anderem [Heimdall]( https://github.com/linuxserver/Heimdall), [NGINX Proxy Manager]( https://github.com/jc21/nginx-proxy-manager), [piHole]( https://github.com/pi-hole/pi-hole), [piVPN]( https://github.com/pivpn/pivpn), [influxDB]( https://github.com/influxdata/influxdb) mit [Grafana]( https://github.com/grafana/grafana) und mehr

## VORAUSSETZUNGEN
Du solltest schonmal einen Computer installiert haben und wissen was IP-Adressen und Subnetzwerke sind. Die Installation von Proxmox ist sehr einfach gehalten und kann je nach Computerleistung in 5-10min abgehandelt werden. Folgende Voraussetzungen sollte der „Server“ mindestens haben:
- Intel EMT64 oder AMD64 mit Intel VT/AMD-V CPU-Flag. Für PCI(e) Passthrough wird eine CPU mit VT-d/AMD-d CPU-Flag benötigt.
- Systemfestplatte für Proxmox mindestens 4GB (falls nur eine Festplatte verbaut ist mindestens 128GB) außerdem sollte die verwendete Festplatte eine SSD sein.
- Netzwerkkarte mit Internetzugang (kein WLAN)

## VERWENDUNG
Du kannst dieses Skript direkt ausführen, indem Du eine Konsole über deine Proxmox WebGUI öffnest und folgendes eingibst:

### Methode 1
`curl -sSL https://install.shiot.de | bash`

### Methode 2 (direct link)
`curl https://raw.githubusercontent.com/shiot/prepve/master/start.sh | bash`

### Methode 3 (clone repo)
```bash
git clone https://github.com/shiot/prepve.git
bash prepve/start.sh
```

Das Skript startet mit einigen Fragen zu deinem System, deiner Proxmox Installation, und deinem Netzwerk. Nach der Auswahl der Container, die du installieren willst, läuft das Skript Großteiles automatisch und führt die Konfiguration von deinem Server, sowie die Installation der gewählten Container aus.

## RECHTLICHE HINWEISE
Dieses Skript richtet sich allein an private Endnutzer. Ich bin kein Programmierer oder Softwareentwickler, komme aber aus der IT-Welt. Dieses Skript kann Fehler enthalten, so genannte Bugs auf Grund derer dein Server unbrauchbar werden kann.
Wenn du dieses Skript benutzt, dann auf eigene Gefahr. Ich bin in keiner Weise dafür verantwortlich, wenn an deinem System etwas kaputt geht, auch wenn die wahrscheinlich dafür verschwindet gering ist.

