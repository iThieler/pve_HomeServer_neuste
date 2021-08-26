#!/bin/bash

ctID=$1                                                    # ID of Container
ctRootpw=$2                                                # Rootpassword of Container generated thru the creation process
ctIP="$3"                                                  # Container IP get via Container ID
containername="$4"                                         # Hostname of the Container

source "$script_path/bin/variables.sh"                     # Load varibale File
source "$script_path/handler/global_functions.sh"          # Load global Functions File
source "$shiot_configPath/$shiot_configFile"               # Load saved configuration variables
source "$script_path/language/$var_language.sh"            # Load global Language File

# If Container Language Folder exist, load container language file if, not exist load english language    #
#if [ -d "$script_path/lxc/$containername/language" ]; then                                               #
#  if [ -f "$script_path/lxc/$containername/language/$var_language.sh" ]; then                            # If custom texts are needed for the container
#    source "$script_path/lxc/$containername/language/$var_language.sh"                                   # configuration, create a folder named "language"
#  else                                                                                                   # in this folder a file named en.sh must be created
#    source "$script_path/lxc/$containername/language/en.sh"                                              #
#  fi                                                                                                     #
#fi                                                                                                       #

### Start with Commands and functions
# Commands are executed on the Proxmox host. To execute a command on the container, use the
# pct exec $ctID -- bash -ci ""
# command and write the desired command in the quotes
