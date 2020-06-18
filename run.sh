#!/bin/bash

/usr/share/geoserver/bin/startup.sh & # Log output is written to geoserver_data/logs/geoserver.log
./scripts/base/cityapp_onesecond.sh | while read -r line; do echo -e "\033[0;32m[Cityapp GIS] $line\033[0m"; done &
./scripts/base/cityapp_module_launcher.sh | while read -r line; do echo -e "\033[0;32m[Cityapp GIS] $line\033[0m"; done &
cd webapp || exit; node app.js | while read -r line; do echo -e "\033[0;33m[Cityapp webapp] $line\033[0m"; done
