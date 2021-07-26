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
