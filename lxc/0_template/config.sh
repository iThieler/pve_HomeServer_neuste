#!/bin/bash

ctID=$1                                                    # ID of Container
ctRootpw=$2                                                # Rootpassword of Container generated thru the creation process
ctIP="$3"                                                  # Container IP get via Container ID
containername="$4"                                         # Hostname of the Container

source "$script_path/bin/variables.sh"                     # Load varibale File
source "$script_path/handler/global_functions.sh"          # Load global Functions File
source "$shiot_configPath/$shiot_configFile"               # Load saved configuration variables
source "$script_path/language/$var_language.sh"            # Load global Language File

### Start with Commands and functions
# Commands are executed on the Proxmox host. To execute a command on the container, use the
# pct exec $ctID -- bash -ci ""
# command and write the desired command in the quotes
