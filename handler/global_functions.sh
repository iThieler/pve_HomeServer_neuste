#!/bin/bash

function pingIP() {
  if ping -c 1 $1 &> /dev/null; then
    return 0
  else
    return 1
  fi
}

function githubLatest() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

function generatePassword() {
# Function generates a random secure Linux password
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
  cat /dev/null > ~/.bash_history && history -c && history -w
}
