#!/bin/bash

nasonly=true                                      # ture or false
userinput=false                                   # true or false

################## Descriptions ###################
desc_en="Containerdescription"                    # is needed
desc_de="Containerbeschreibung"

################### Info E-Mail ###################
commandsAfterCFG="apt-get install -y XXX"         # Commands that the user must execute, line break with \n
                                                  # If the variable is empty, no e-mail will be sent

mail_en="Text to send per e-mail"                 # is needed
mail_de="Text der per E-Mail versendet werden soll"
