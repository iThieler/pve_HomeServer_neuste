#!/bin/bash

echo -e "[group downloadserver]\n\nIN ACCEPT -source +network -p tcp -dport 6767 -log nolog # Weboberfläche sabNZBd\nIN ACCEPT -source +network -p tcp -dport 7878 -log nolog # Weboberfläche Radarr\nIN ACCEPT -source +network -p tcp -dport 8989 -log nolog # Weboberfläche Sonarr\n\n" >> $fwcluster
