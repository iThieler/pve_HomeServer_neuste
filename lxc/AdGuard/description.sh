#!/bin/bash

nasonly=false

################## Descriptions ###################
desc_en="Server for network-wide blocking of advertising"
desc_de="Server zum netzwerkweiten Blockieren von Werbung"

################### Info E-Mail ###################
commandsAfterCFG="bash make_conf.sh"

mail_en="Due to the password encryption of AdGuradHome, it is not possible to automate the process. After the initial configuration via the AdGuard web interface, you need to log into the console of the container and enter the following command."
mail_de="Aufgrund der Passwortverschlüsselung von AdGuradHome ist es nicht möglich den Prozess zu automatisieren. Nach der Erstkonfiguration über die Weboberfläche von AdGuard, musst Du dich in die Konsole des Containers einloggen und folgenden Befehl eingeben."
