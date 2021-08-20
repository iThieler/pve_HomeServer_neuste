#!/bin/bash

pct exec $1 -- bash -ci "curl -sLf https://iobroker.net/install.sh | bash - > /dev/null 2>&1"
iobinstallVariation

exit 0
