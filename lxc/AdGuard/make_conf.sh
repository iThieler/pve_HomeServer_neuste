#!/bin/bash

if [ -f "/opt/AdGuardHome/AdGuardHome.yaml" ]; then
  /opt/AdGuardHome/AdGuardHome -s stop

  cp /opt/AdGuardHome/AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml.bak

  sed -i "s|- https://dns10.quad9.net/dns-query|- https://cloudflare-dns.com/dns-query\n  - https://dns10.quad9.net/dns-query\n  - https://dns.google/dns-query|" /opt/AdGuardHome/AdGuardHome.yaml
  sed -i "s|filters_update_interval: 24|filters_update_interval: 12|" /opt/AdGuardHome/AdGuardHome.yaml
  sed -i "s|safebrowsing_enabled: false|safebrowsing_enabled: true|" /opt/AdGuardHome/AdGuardHome.yaml
  sed -i "s|- enabled: false|- enabled: true|g" /opt/AdGuardHome/AdGuardHome.yaml
  sed -i "s|id: 2|id: 2\n\
- enabled: true\n\
  url: https://raw.githubusercontent.com/DandelionSprout/adfilt/master/GameConsoleAdblockList.txt\n\
  name: Game Console Adblock List\n\
  id: 4\n\
- enabled: true\n\
  url: https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV-AGH.txt\n\
  name: Perflyst and Dandelion Sprout's Smart-TV Blocklist\n\
  id: 5\n\
- enabled: true\n\
  url: https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt\n\
  name: WindowsSpyBlocker - Hosts spy rules\n\
  id: 6\n\
- enabled: true\n\
  url: https://curben.gitlab.io/malware-filter/urlhaus-filter-agh-online.txt\n\
  name: Online Malicious URL Blocklist\n\
  id: 7\n\
- enabled: true\n\
  url: https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt\n\
  name: NoCoin Filter List\n\
  id: 8\n\
- enabled: true\n\
  url: https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt\n\
  name: Spam404\n\
  id: 9\n\
- enabled: true\n\
  url: https://raw.githubusercontent.com/durablenapkin/scamblocklist/master/adguard.txt\n\
  name: Scam Blocklist by DurableNapkin\n\
  id: 10\n\
- enabled: true\n\
  url: https://raw.githubusercontent.com/mitchellkrogza/The-Big-List-of-Hacked-Malware-Web-Sites/master/hosts\n\
  name: The Big List of Hacked Malware Web Sites\n\
  id: 11|" /opt/AdGuardHome/AdGuardHome.yaml

  /opt/AdGuardHome/AdGuardHome -s start
  rm -f ./make_conf.sh
else
  echo -e "You need to perform the initial setup via the web interface first. Start via the web page http:\\\\\\$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d/ -f1):3000"
fi

exit
