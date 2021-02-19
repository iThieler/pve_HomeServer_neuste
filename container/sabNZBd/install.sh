apt-get update && apt-get upgrade -y
apt-get install software-properties-common
add-apt-repository multiverse
add-apt-repository universe
add-apt-repository ppa:jcfp/nobetas
add-apt-repository ppa:jcfp/sab-addons
apt-get update && sudo apt-get dist-upgrade
apt-get install sabnzbdplus
nano /etc/default/sabnzbdplus             ### Datei bearbeiten
                                          ### INI-Download
IPADRESSTOCHANGE    ### bearbeiten
APIKEYTOCHANGE      ### bearbeiten
NZBAPIKEYTOCHANGE   ### bearbeiten

systemctl start sabnzbdplus && systemctl enable sabnzbdplus
apt-get install cifs-utils
                                          ### NAS einbinden
