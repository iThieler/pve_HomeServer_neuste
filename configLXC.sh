#!/bin/bash

##################### Operating systems ###################

osAlpine3_11="alpine-3.11-default"       # Container Template for Alpine v3.11
osAlpine3_12="alpine-3.12-default"       # Container Template for Alpine v3.12
osArchlinux="archlinux-base"             # Container Template for archLinux
osCentos7="centos-7-default"             # Container Template for Centos v7
osCentos8="centos-8-default"             # Container Template for Centos v8
osDebian9="debian-9.0-standard"          # Container Template for Debian v9
osDebian10="debian-10-standard"          # Container Template for Debian v10
osDevuan3_0="devuan-3.0-standard"        # Container Template for Devuan v3.0
osFedora32="fedora-32-default"           # Container Template for Fedora v32
osFedora33="fedora-33-default"           # Container Template for Fedora v33
osGentoo="gentoo-current-default"        # Container Template for current Gentoo
osOpensuse15_2="opensuse-15.2-default"   # Container Template for openSUSE v15.2
osUbuntu18_04="ubuntu-18.04-standard"    # Container Template for Ubuntu v18.04
osUbuntu20_04="ubuntu-20.04-standard"    # Container Template for Ubuntu v20.04
osUbuntu20_10="ubuntu-20.10-standard"    # Container Template for Ubuntu v20.10

#################### Required software ####################

lxc_Standardsoftware="curl wget software-properties-common apt-transport-https lsb-release gnupg2 net-tools"  #Software that is installed first on each LXC

##################### Script Variables ####################

# Divide by two so the dialogs take up half of the screen, which looks nice.
r=$(( rows / 2 ))
ri=$(( rows / 2 ))
c=$(( columns / 2 ))
# Unless the screen is tiny
r=$(( r < 20 ? 20 : r ))
ri=$(( r < 10 ? 10 : r ))
c=$(( c < 80 ? 80 : c ))

# check if Variable is valid URL
regexURL='^(https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'
if [[ $2 == "shiot" ]]; then
  rawContainerURL="https://raw.githubusercontent.com/shiot/lxc_HomeServer/master"
else
  rawContainerURL="${2}"
fi

# check if Script runs FirstTime
configFile="/root/.cfg_shiot"
recoverConfig=false

# Container Variables
ctIDall=$(pct list | tail -n +2 | awk '{print $1}')
ctHostname="${1}"

######################## Functions ########################

function generatePassword() {
# Function generates a random secure password
  chars=({0..9} {a..z} {A..Z} "_" "%" "&" "+" "-")
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

function generateAPIKey() {
# Function generates a random API-Key
  chars=({0..9} {a..f})
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

function cleanupHistory() {
# Function clean the Shell History
  pct exec $1 -- bash -ci "cat /dev/null > ~/.bash_history && history -c && history -w"
}



####################### start Script ######################

source $configFile

echo "ctHostname=${1}"
echo "rawContainerURL=${2}"

exit
