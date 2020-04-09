#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.3
# CityApp module
# Stop and start  -- in this order -- Geoserver
# Only have to do when a new map is defined, so normally not too often... :)
# 2020. február 11.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
VARIABLES=~/cityapp/scripts/shared/variables
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/restart_geoserver
MESSAGE_SENT=~/cityapp/data_to_client
MODULES=~/cityapp/scripts/modules/
MODULE=~/cityapp/scripts/modules/restart_geoserver
BROWSER=~/cityapp/data_from_browser




if [ -e /usr/share/geoserver/bin/shutdown.sh ]
    then
        cd /usr/share/geoserver/bin/
        ./shutdown.sh  
        ./startup.sh &
    else
        Send_Messagem m 1 restart_geoserver.1 error actions [\"ok\"]
fi

exit
