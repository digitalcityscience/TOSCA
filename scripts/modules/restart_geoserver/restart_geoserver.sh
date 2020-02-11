#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.2
# CityApp module
# Stop and start  -- in this order -- Geoserver
# Only have to do when a new map is defined, so normally not too often... :)
# 2020. február 11.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/restart_geoserver
MESSAGE_SENT=~/cityapp/data_to_client

if [ -e /usr/share/geoserver/bin/shutdown.sh ]
    then
        cd /usr/share/geoserver/bin/
        ./shutdown.sh  
        ./startup.sh &
    else
        Send_Messagem m 1 restart_geoserver.1 error actions [\"ok\"]
fi

exit
