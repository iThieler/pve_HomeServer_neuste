#!/bin/bash

##################### Container Commands ######################

lxcCommands="wget -qO - http://downloads-global.3cx.com/downloads/3cxpbx/public.key | apt-key add - > /dev/null 2>&1
            echo \"deb http://downloads-global.3cx.com/downloads/debian stretch main\" | tee /etc/apt/sources.list.d/3cxpbx.list > /dev/null 2>&1
            apt-get install -y iperf libicu57 libicu57 dphys-swapfile 3cxpbx > /dev/null 2>&1"

######################## Host Commands ########################

pveCommands=""