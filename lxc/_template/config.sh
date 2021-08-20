#!/bin/bash

ctID=$1                                                  # ID of Container
ctRootpw=$2                                              # Rootpassword of Container generated thru the creation process
ctIP=$(lxc-info $ctID -iH | grep $networkIP)             # Container IP get via Container ID
containername=$(pct list | grep 100 | awk '{print $3}')  # Hostname of the Container

source "$script_path/bin/variables.sh"                              # Load varibale File
source "$script_path/handler/global_functions.sh"                   # Load global Functions File
source "$shiot_configPath/$shiot_configFile"                        # Load saved configuration variables
source "$script_path/language/$var_language.sh"                     # Load global Language File
source "$script_path/lxc/$containername/language/$var_language.sh"  # Load Container Language File

### Start with Commands and functions