# Proxmox Konfigurationsscript

    ##################### Rechtliche Hinweise / Legal notice - Deutsch / German ######################
    #                                                                                                #
    # Ein Skript, welches schnell und einfach die ersten wichtigsten Konfigurationen von Proxmox VE  #
    # übernimmt. Nach der Ausführung dieses Skripts sind E-Mailbenachrichtigungen, Firewall          #
    # Einstellungen, Backups und evtl. ZFS-Pools in Proxmox VE eingerichtet. Außerdem werden einige  #
    # Container (CT) / virtuelle Maschinen (VM) eingerichtet. Ziel ist es Neulingen den einstieg     #
    # in Proxmox VE zu erleichtern und schnell einen "sicheren" Homeserver an die Hand zu geben.   #
    #                                                                                                #
    # \e[1;35mHAFTUNGSAUSSCHLUSS\e[0m                                                                             #
    # Ich gehe davon aus, dass Du weisst was Du tust, und es sich um ein neu installiertes System    #
    # in der Standardkonfiguration handelt.                                                          #
    #                                                                                                #
    # !!! Ich bin in keiner Weise dafür verantwortlich, wenn an deinem System etwas kaputt geht,     #
    # auch wenn die wahrscheinlich dafür verschwindet gering ist !!!                                 #
    #                                                                                                #
    # Ich bin kein Programmierer oder Softwareentwickler. Ich versuche nur, einigen Anfängern das    #
    # Leben ein wenig zu erleichtern. ;-)                                                            #
    #                                                                                                #
    # Es wird Bugs oder Dinge geben, an die ich nicht gedacht habe - sorry - wenn das so ist,        #
    # versuchst Du am besten es selbst zu lösen oder lass es mich bitte wissen, eventuell kann ich   #
    # dir helfen das Problem zu lösen.                                                               #
    #                                                                                                #
    # \e[1;35mVERWENDUNG\e[0m                                                                                     #
    # Du kannst dieses Skript direkt ausführen, indem Du eine Konsole über deine Proxmox WebGUI      #
    # öffnest und folgendes eingibst:                                                                #
    # # bash <(wget -qO- https://install.shiot.de/pveConfig.sh)                                      #
    #                                                                                                #
    # Du kannst dieses Skript vor der Benutzung bearbeiten in dem Du es in der Shell herunterlädst   #
    # # wget https://install.shiot.de/pveConfig.sh                                                   #
    #                                                                                                #
    ##################################################################################################
    
    
curl -sSL https://install.shiot.de | bash
