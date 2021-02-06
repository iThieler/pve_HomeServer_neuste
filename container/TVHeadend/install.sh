#!/bin/bash

echo -e "[group tvheadend]\n\nIN ACCEPT -p tcp -dport 9982 -log nolog # HTSP (Streaming protocol)\nIN ACCEPT -source +network -p tcp -dport 9981 -log nolog # Weboberfläche\n\n" >> $fwcluster
