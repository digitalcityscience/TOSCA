#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 0.1
# CityApp module
# This module is the simplest time map calculator.
# Calculate the fastest way from "from_points" to "to_points" thru "via_points".
# This module only allows to load points from interactively from the map.
# Using already existing maps is not allowed.
# The network is the road network, with user-defined average speed.
# Defining "from_points" is mandatory, "via_points" and "to_points" are optional.
# If no "to_points" are selected, the default "to_points" will used: points along the roads, calculated by the application. 
# 2020. július 26.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#



cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/test
MODULE_NAME=cityapp_test
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/test
MESSAGE_SENT=~/cityapp/data_to_client
GEOSERVER=~/cityapp/geoserver_data
GRASS=~/cityapp/grass/global
MAPSET=module_1
DATE_VALUE=$(date +%Y-%m-%d" "%H":"%M)
DATE_VALUE_2=$(date +%Y_%m_%d_%H_%M)
#
#-- Default constants values for the interpolation and time calculations. Only modify when you know what is the effects of these variables -------------------
#

SMOOTH=4
TENSION=30
BASE_RESOLUTION=0.0005
AVERAGE_SPEED=40
ROAD_POINTS=0.003
CONNECT_DISTANCE=0.003

Running_Check start

    # Changing speed values?
    Send_Message m 1 test.1 question actions [\"Yes\",\"No\"] 
        Request
            case $REQUEST_CONTENT in
                "yes"|"Yes"|"YES")
                    Send_Message l 2 test.2 select actions [\"OK\"] $VARIABLES/roads_speed
                        Request
                            # echo $REQUEST_CONTENT > $VARIABLES/roads_speed;;
                    # Specific value will serves as speed value for non classified elements and newly inserted connecting line segments. Speed of these features will set to speed of service roads
                    #REDUCING_RATIO=$(cat $VARIABLES/roads_speed | head -n$n | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                    ;;
                "no"|"No"|"NO")
                    ;;
            esac

    Running_Check Stop
    Close_Process
exit
