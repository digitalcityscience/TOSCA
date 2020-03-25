#!/bin/bash

/usr/share/geoserver/bin/startup.sh | while read line; do echo -e "\033[0;36m[GeoServer] $line\033[0m"; done &
./scripts/base/ca_starter.sh | while read line; do echo -e "\033[0;32m[Cityapp GIS] $line\033[0m"; done &
cd webapp; node app.js | while read line; do echo -e "\033[0;33m[Cityapp webapp] $line\033[0m"; done
