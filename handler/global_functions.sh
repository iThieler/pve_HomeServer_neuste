#!/bin/bash

# Function ping given IP and return TRUE if available
function pingIP() {
  if ping -c 1 $1 &> /dev/null; then
    return 0
  else
    return 1
  fi
}

# Function get latest release from GitHub api
function githubLatest() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | 
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# Function generates a random secure Linux password
function generatePassword() {
  chars=({0..9} {a..z} {A..Z} "_" "%" "&" "+" "-")
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

# Function generates a random API-Key
function generateAPIKey() {
  chars=({0..9} {a..f})
  for i in $(eval echo "{1..$1}"); do
    echo -n "${chars[$(($RANDOM % ${#chars[@]}))]}"
  done 
}

# Function clean the Shell History
function cleanupHistory() {
  cat /dev/null > ~/.bash_history && history -c && history -w
}

function lxc_mountNAS(){
  ############################################################
}

function lxc_SQLSecure() {
# Function configures SQL secure in LXC Containers
  ctID=$1
  SECURE_MYSQL=$(expect -c "
  set timeout 3
  spawn mysql_secure_installation
  expect \"Press y|Y for Yes, any other key for No:\"
  send \"n\r\"
  expect \"New password:\"
  send \"${ctRootPW}\r\"
  expect \"Re-enter new password:\"
  send \"${ctRootPW}\r\"
  expect \"Remove anonymous users?\"
  send \"y\r\"
  expect \"Disallow root login remotely?\"
  send \"y\r\"
  expect \"Remove test database and access to it?\"
  send \"y\r\"
  expect \"Reload privilege tables now?\"
  send \"y\r\"
  expect eof
  ")

  pct exec $ctID -- bash -ci "apt-get install -y expect > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "echo \"${SECURE_MYSQL}\" > /dev/null 2>&1"
  pct exec $ctID -- bash -ci "apt-get purge -y expect > /dev/null 2>&1"
}
