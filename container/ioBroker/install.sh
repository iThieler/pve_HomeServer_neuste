#!/bin/bash

echo -e "[group iobroker]\n\nIN ACCEPT -p tcp -dport 8082 -log nolog # Weboberfläche\nIN ACCEPT -source +network -log nolog\n\n" >> $fwcluster