#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 0.31
# CityApp module
# This module is to query any existing map by a user-defined area -- querying attribute data only
# 2020. júliu 2.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/module_2b
MODULE_NAME=module_2b
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_2b
MESSAGE_SENT=~/cityapp/data_to_client
GEOSERVER=~/cityapp/geoserver_data
GRASS=~/cityapp/grass/global
MAPSET=module_2
DATE_VALUE=$(date +%Y-%m-%d" "%H":"%M)
DATE_VALUE_2=$(date +%Y_%m_%d_%H_%M)

QUERY_RESOLUTION=0.00002

Running_Check start

##############
# Preprocess, 
##############

    rm -f $MESSAGE_SENT/*

    # First overwrite the region of module_2 mapset. If no such mapset exist, create it
        if [ -d $GRASS/$MAPSET ]
            then
                cp $GRASS/PERMANENT/WIND $GRASS/$MAPSET/WIND
            else
                mkdir $GRASS/$MAPSET
                cp -r ~/cityapp/grass/skel/* $GRASS/$MAPSET
                cp $GRASS/PERMANENT/WIND $GRASS/$MAPSET/WIND
        fi

        # RUNNING_MODE=$(cat $MODULE/mode)

#############
# User input
#############

    #  If you want to draw a new query area, click 'Draw' button, draw the area you want to query, then click 'Save'. If you want to exit, click 'Cancel'.
        Send_Message m 1 module_2b.1 question actions [\"Map\",\"Draw\",\"Cancel\"]
            Request
            case $REQUEST_CONTENT in
                "draw"|"Draw"|"DRAW")
                    Request_Map geojson GEOJSON
                    
                        Process_Check start add_map
                        Add_Vector $REQUEST_PATH query_area_1
                        Gpkg_Out query_area_1
                        QUERY_AREA_1=query_area_1
                    
                        Process_Check stop add_map
                     ;;
                "cancel"|"Cancel"|"CANCEL")
                    # To process exit, click OK.
                    Send_Message m 2 module_2b.2 question actions [\"OK\"]
                        Request
                        Running_Check stop
                        Close_Process
                    exit;;
            esac
        
##############
#  Processing 
##############

    Process_Check start calculations
    
        grass $GRASS/$MAPSET --exec ~/cityapp/scripts/modules/module_2b/module_2b_query_process.sh
    
    Process_Check stop calculations
    
    
    # To process exit, click OK.
    Send_Message m 2 module_2b.2 question actions [\"OK\"]
        Request
            Running_Check stop
            Close_Process
exit
