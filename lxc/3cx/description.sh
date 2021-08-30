#!/bin/bash

nasonly=false
userinput=false

################## Descriptions ###################
desc_en="VoIP Phone System"
desc_de="VoIP Telefonanlage"

################## Info E-Mail ###################
commandsAfterCFG="apt-get install -y 3cxpbx"

mail_en="Since user input is required when installing the phone system software, you must log in to the container's console and run the following command. Sorry for the inconvenience."
mail_de="Da bei der Installation der Telefonanlagensoftware Benutzereingaben benötigt werden, musst du dich an der Konsole des Containers einloggen und folgenden Befehl ausführen. Entschuldige die Umstände."
