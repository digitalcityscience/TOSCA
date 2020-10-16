#!/bin/bash

/usr/share/geoserver/bin/startup.sh 2>&1 | while read -r line; do echo -e "\033[0;36m[GeoServer] $line\033[0m"; done &
cd webapp || exit; node app.js | while read -r line; do echo -e "\033[0;33m[OCT webapp] $line\033[0m"; done
