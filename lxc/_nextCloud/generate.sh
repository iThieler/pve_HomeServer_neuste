#!/bin/bash

# ${osAlpine3_11}     for    Alpine v3.11 Container Template
# ${osAlpine3_12}     for    Alpine v3.12 Container Template
# ${osArchlinux}      for    archLinux Container Template
# ${osCentos7}        for    Centos v7 Container Template
# ${osCentos8}        for    Centos v8 Container Template
# ${osDebian9}        for    Debian v9 Container Template
# ${osDebian10}       for    Debian v10 Container Template
# ${osDevuan3_0}      for    Devuan v3.0 Container Template
# ${osFedora32}       for    Fedora v32 Container Template
# ${osFedora33}       for    Fedora v33 Container Template
# ${osGentoo}         for    current Gentoo Container Template
# ${osOpensuse15_2}   for    openSUSE v15.2 Container Template
# ${osUbuntu18_04}    for    Ubuntu v18.04 Container Template
# ${osUbuntu20_04}    for    Ubuntu v20.04 Container Template
# ${osUbuntu20_10}    for    Ubuntu v20.10 Container Template

############# Container Configuration #############

template=                                         # possible input options can be found above
hddsize=                                          # Hard disk size in GB
cpucores=                                         # Processor count
memory=                                           # Used main memory in MB
swap=                                             # Swap size in MB
unprivileged=                                     # 0 or 1
features=""                                       # Features to be used in the container

############### WebGUI Configuration ##############

webgui=true
webguiName=( "" "" "" )
webguiPort=( "" "" "" )
webguiPath=( "" "" "" )
webguiUser=( "" "" "" )
webguiPass=( "" "" "" )
webguiProt=( "" "" "" )

############## Firewall Configuration #############

fwPort=( "" "" "" )
fwNetw=( "" "" "" )
fwProt=( "" "" "" )
fwDesc=( "" "" "" )

############### Needed Hardwarebinds ##############

nasneeded=false
dvbneeded=false
vganeeded=false

################# Needed Services #################

smtpneeded=false
apparmorProfile=""
sambaneeded=false
sambaUser=""
