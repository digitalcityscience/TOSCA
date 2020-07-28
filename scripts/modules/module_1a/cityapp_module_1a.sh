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
MODULE=~/cityapp/scripts/modules/module_1a
MODULE_NAME=cityapp_module_1a
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_1a
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

#
#-- Preprocess -------------------
#
        
    rm -f $MESSAGE_SENT/*
    rm -f $MODULE/variable_values
    touch $MODULE/variable_values

    if [ ! -d $GRASS/PERMANENT ]
        then
            # check if PERMANENT mapeset exist
            # No valid location found. Run "Set new location" to create a valid location. Module  is now exiting.
                Send_Message m 7 module_1a.7 error actions [\"Ok\"]
                    Request
                        until [ "$REQUEST_CONTENT" == "ok" ]; do
                            rm -f $MESSAGE_SENT/*.message
                            Send_Message m 12 module_1.14 question actions [\"OK\"]
                                Request
                        done

                Running_Check Stop
                Close_Process
                exit
    fi

    # First overwrite the region of module_1 mapset. If no such mapset exist, create it
        if [ -d $GRASS/$MAPSET ]
            then
                # It is simpler and faster to always copy the PERMANENT WIND than to check if is it chaged or not
                    cp $GRASS/PERMANENT/WIND $GRASS/$MAPSET/WIND
            else
                # Scorched earth. Brand new mapset. Everithing has to build everithing.
                    mkdir $GRASS/$MAPSET
                    cp -r ~/cityapp/grass/skel/* $GRASS/$MAPSET
                    cp $GRASS/PERMANENT/WIND $GRASS/$MAPSET/WIND
                
                # Clip lines and polygons@PERMANENT mapset with the area_of_interest, defined by the user 
                # Results will stored in the "module_1" mapset
                
                    Process_Check start map_calculations
                
                    grass $GRASS/$MAPSET --exec g.copy vector=selection@PERMANENT,selection --overwrite --quiet
                    grass $GRASS/$MAPSET --exec g.copy vector=lines@PERMANENT,lines --overwrite --quiet
                    
                    Process_Check stop map_calculations
                    
                # get center coordinates from file
                    EAST=$(cat $VARIABLES/coordinate_east)
                    NORTH=$(cat $VARIABLES/coordinate_north)

        fi        

    # Creating empty maps for ps output, if no related maps are created/selected by user:
    # m1_via_points m1_to_points, m1_stricken_area
    # If user would create a such map, empty maps will automatically overwritten
        v.edit map=m1_via_points tool=create
        v.edit map=m1_to_points tool=create
        v.edit map=m1_stricken_area tool=create

# User communication    

    # Start point is required. If you want to add a start point now, click Yes, then draw one or more point and click Save button. To exit, click Cancel.
        grass $GRASS/$MAPSET --exec g.list -m type=vector > $MODULE/temp_list
        Send_Message m 1 module_1a.1 question actions [\"Yes\",\"No\"]
            Request
                case $REQUEST_CONTENT in
                    "yes"|"Yes"|"YES")
                        Request_Map geojson GEOJSON
                            Process_Check start add_map
                            Add_Vector $REQUEST_PATH m1_from_points
                            Gpkg_Out m1_from_points m1_from_points
                            Process_Check stop add_map
                        ;;
                    "cancel"|"Cancel"|"CANCEL")
                        Send_Message m 5 module_1a.5 question actions [\"OK\"]
                            Request
                                until [ "$REQUEST_CONTENT" == "ok" ]; do
                                    rm -f $MESSAGE_SENT/*.message
                                    Send_Message m 5 module_1a.5 question actions [\"OK\"]
                                        Request
                                done
                                Running_Check stop
                                Close_Process
                        exit
                        ;;
                esac
            
    # Via point is optional. If you want to add a via points, click Yes, then draw one or more point and click Save button. If you do not want to add via point, click Cancel.
        Send_Message m 2 module_1a.2 question actions [\"Yes\",\"Cancel\"]
            Request
                case $REQUEST_CONTENT in
                    "yes"|"Yes"|"YES")
                        VIA=0
                        Request_Map geojson GEOJSON
                            FRESH=$REQUEST_PATH
                            
                            Process_Check start map_calculations
                            Add_Vector $FRESH m1_via_points
                            Gpkg_Out m1_via_points m1_via_points
                            Process_Check stop map_calculations
                            ;;
                    "cancel"|"Cancel"|"CANCEL")
                        VIA=2
                        rm -f $GEOSERVER/m1_via_points".gpkg"
                        ;;
                esac
        
    # Stricken area is optional. If you want to add stricken area, click Yes, then draw one or more area and click Save button. If you do not want to add an area, click Cancel.
        Send_Message m 3 module_1a.3 question actions [\"Yes\",\"Cancel\"]
            Request
                case $REQUEST_CONTENT in
                    "yes"|"Yes"|"YES")
                        AREA=0
                        Request_Map geojson GEOJSON
                            FRESH=$REQUEST_PATH
                            
                            Process_Check start add_map
                            Add_Vector $FRESH m1_stricken_area
                            Gpkg_Out m1_stricken_area m1_stricken_area
                            Process_Check stop add_map
                    
                        Send_Message m 4 module_1a.4 input action [\"OK\"]
                            Request
                                #speed duction ratio value
                                echo $REQUEST_CONTENT > $MODULE/variable_values
                            ;;
                    "cancel"|"Cancel"|"CANCEL")
                        AREA=2
                        rm -f $GEOSERVER/m1_stricken_area".gpkg"
                        ;;
                esac


                echo $VIA >> $MODULE/variable_values
                echo $AREA >> $MODULE/variable_values

# -- Processing --------------------------ˇ
#

    Process_Check start map_calculations
        
    grass $GRASS/$MAPSET --exec ~/cityapp/scripts/modules/module_1a/cityapp_module_1a_processing.sh
        
    Process_Check stop map_calculations

    Send_Message m 6 module_1a.6 question actions [\"OK\"]
        Request
            until [ "$REQUEST_CONTENT" == "ok" ]; do
                rm -f $MESSAGE_SENT/*.message
                Send_Message m 6 module_1a.6 question actions [\"OK\"]
                    Request
            done

        Running_Check Stop
        Close_Process
exit
