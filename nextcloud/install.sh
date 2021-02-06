#!/bin/bash

echo -e "[group nextcloud]\n\nIN HTTPS(ACCEPT) -log nolog # Weboberfläche HTTPs\nIN HTTP(ACCEPT) -source +network -log nolog # Weboberfläche\n\n" >> $fwcluster
