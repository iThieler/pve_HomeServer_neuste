#!/bin/bash

# Buttons
btn_1="OK"
btn_2="CANCEL"
btn_3="YES"
btn_4="NO"
btn_5="RECOVER"
btn_6="CONFIG"
btn_7="CHECK"

# Titles
tit_1="ERROR"
tit_2="NAS"
tit_3="NETWORK ROBOT"
tit_4="VLAN"
tit_5="MAILSERVER"
tit_6="LXC configuration"
tit_7="VM configuration"
tit_8="WARNING"

# Words
wrd_1="Username"
wrd_2="Password"
wrd_3="Home network"
wrd_4="Basic configuration"
wrd_5="Preparation"
wrd_6="Name"
wrd_7="ID"
wrd_8="User"
wrd_9="Web address"
wrd_10="NAS"
wrd_11="Media directory"
wrd_12="Backup directory"
wrd_13="Share path"

# start.sh
txt_0001="Script language changed to"
txt_0002="Unfortunately, the default configuration directory could not be found."
txt_0003="It looks like this server is a new installation."
txt_0004="Do you want to reconfigure this server, or do you want to load a previously saved configuration file from your NAS (recovery)?"
txt_0005="What is the IP address of your NAS?"
txt_0006="What is the name of the folder where the file can be found (without \"\\\" at the beginning or at the end)?"
txt_0007="What is the name of the file that contains the configuration variables?"
txt_0008="What is the username of the user that has read permissions on your NAS?"
txt_0009="What is the password of"
txt_0010="Configuration file copied successfully"
txt_0011="The configuration file was created successfully"
txt_0012="The configuration file could not be created, this script will be terminated prematurely"
txt_0013="Proxmox base configuration successfully finished"
txt_0014="Proxmox base configuration not finished successfully"
txt_0015="Do you want to install containers in Proxmox?"
txt_0016="The conatiner was created and configured successfully"
txt_0017="A conatiner configuration is not desired"
txt_0018="Do you want to install virtual machines in Proxmox?"
txt_0019="Virtual machines created successfully"
txt_0020="Virtual machine configuration is not desired"
txt_0021="The shell history of Proxmox history has been cleaned"

# handler/generate_config.sh
txt_0051="What is the username you assigned to your network robot?"
txt_0052="What is the password you assigned to your network robot?"
txt_0053="If you don't enter a password here, a secure 26-character password will be created automatically."
txt_0054="Create a user on your NAS with the following data and assign this user administrator rights."
txt_0055="2 Shared Folders are needed on your NAS, if not present create them and assign read/write privileges to your network robot before continuing."
txt_0056="Are you using virtual networks (VLANs)?"
txt_0057="What VLAN ID are you using for your server network?"
txt_0058="What VLAN ID are you using for your SmartHome network?"
txt_0059="Which VLAN ID do you use for your guest network?"
txt_0060="To which email address should notifications from your server be sent?"
txt_0061="What is the address of your outgoing mail server?"
txt_0062="What port is used for yours?"
txt_0063="Does your mail server require TLS/STARTTLS for login?"
txt_0064="What username is used to login to the mail server?"
txt_0065="What is the password used to login to the mail server?"
txt_0066="What is the sending address from which your emails will be sent?"
txt_0067="Are you using a NAS on your network?"
txt_0068="What is the IP address of your NAS?"
txt_0069="Do you want your passwords to be stored unencrypted in plain text in the configuration file?"

# bin/config_pve6.sh
txt_0101="Your NAS will be mounted in Proxmox"
txt_0102="Containers in this pool are included in the daily backup"
txt_0103="Proxmox repository will be changed (community)"
txt_0104="Enable S.M.A.R.T. on the system disk"
txt_0105="Configure e-mail notification about system disk errors"
txt_0106="Enable and configure Proxmox Firewall"
txt_0107="all private networks, important for VPN"
txt_0108="Additional SSD is bound to Proxmox"
txt_0109="Mailserver successfully configured"
txt_0110="Mailserver configuration not successful"

# bin/config_email.sh
txt_0151="This is a test message, sent by the configuration script from https://SmartHome-IoT.net"
txt_0152="If you have received this email, you can continue with your HomeServer configuration by confirming receipt of this email."
txt_0153="Mailserver successfully set up"
txt_0154="An e-mail was sent to the following address"
txt_0155="Was the email successfully delivered? (Depending on the provider, this can take up to 15 minutes)"
txt_0156="The log file is now checked for known errors, any errors found are automatically fixed."
txt_0157="You can find the error log in the following file."

# handler/gnerate_lxc.sh
txt_0201="Create a list of available containers"
txt_0202="The following container has been created and is now prepared for configuration"
txt_0203="Container configuration successfully completed"
txt_0204="The container could not be configured"
txt_0205="The container could not be created"
txt_0206="Select the containers you want to install. Enabled containers are already installed, if you disable them they will be uninstalled."
txt_0207="The container could not be created because it already exists"
txt_0208="The following container will be deleted."
txt_0209="Are you sure you want to continue?"
txt_0210="The following container was removed"

# bin/config_lxc_sh.sh
txt_0251="No NAS can be bound to the container as none is configured"
txt_0252="The container is being updated"
txt_0253="Container software is being installed"
txt_0254="Container is being configured"
txt_0255="Container is configured in Proxmox"
txt_0256="Container configuration is completed"
txt_0257="The Proxmox firewall is configured for the container"
txt_0258="Delete history data in the container"
