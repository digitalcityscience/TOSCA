#! /bin/bash
# version 1.0
# CityApp maintenance
# Stop and start  -- in this order -- Geoserver
# Only have to do when a new map is defined, so normally not too often... :)
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany
# 2020. január 24.

MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/restart_geoserver

if [ -e /usr/share/geoserver/bin/shutdown.sh ]
    then
        cd /usr/share/geoserver/bin/
        ./shutdown.sh 
        ./startup.sh 
    else
        kdialog --error "problem!"
fi
