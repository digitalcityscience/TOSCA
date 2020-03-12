#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.3
# CityApp module
# Adding new layers to a selected mapset
# 2020. március 8.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/add_map
MODULE_NAME=cityapp_add_map
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/add_map
MESSAGE_SENT=~/cityapp/data_to_client
GRASS=~/cityapp/grass/global
MAPSET=PERMANENT
GEOSERVER=~/cityapp/geoserver_data

#
#-- Process -----------------------------
#

touch $VARIABLES/launch_locked
echo "add_map" > $VARIABLES/launch_locked

if [ ! $(grass $GRASS/$MAPSET --exec g.list type=vector | grep selection) ]
    then
        # Message 1 "Selection" map not found. Before adding a new layer, first you have to define a location and a selection. For this end please, use Location Selector tool of CityApp. Add_Map modul now quit.
        Send_Message m 1 add_map.1 error actions [\"Ok\"]
            Request
            Close_Process
            exit
    else
        # Message 2 Do you really want to add a new map to CityApp mapset?
        Send_Message m 2 add_map.2 question actions [\"Yes\",\"No\"]
            Request
                if [ "$REQUEST_CONTENT" == "yes" ]
                    then
                        #Message: Select a map to add CityApp. Only gpkg (geopackage) and openstreetmap vector files and geotiff (gtif or tif) raster files are accepted.
                        Send_Message m 3 add_map.3 upload actions [\"Yes\"]
                            Request_Map geojson GEOJSON gpkg GPKG tif TIF tiff TIFF gtif GTIF
                                if [[ $REQUEST_FILE =~ ".geojson" ]] || [[ $REQUEST_FILE =~ ".GEOJSON" ]] || [[ $REQUEST_FILE =~ ".gpkg" ]] || [[ $REQUEST_FILE =~ ".GPKG" ]]
                                    then
                                        FILE_TO_IMPORT=$REQUEST_PATH
                                        #Message: Please, define an output map name.
                                        Send_Message m 4 add_map.4 input actions [\"Yes\"]
                                            Request
                                                MAP_NAME=$REQUEST_CONTENT
                                                Add_Vector $FILE_TO_IMPORT $MAP_NAME
                                                
                                fi
                                if  [[ $REQUEST_FILE =~ ".tif" ]] || [[ $REQUEST_FILE =~ ".TIF" ]] || [[ $REQUEST_FILE =~ ".tiff" ]] || [[ $REQUEST_FILE =~ ".TIFF" ]] || [[ $REQUEST_FILE =~ ".gtif" ]] || [[ $REQUEST_FILE =~ ".GTIF" ]]
                                    then
                                        FILE_TO_IMPORT=$REQUEST_PATH
                                        #Message: Please, define an output map name.
                                        Send_Message m 4 add_map.4 input actions [\"Yes\"]
                                            Request
                                                MAP_NAME=$REQUEST_CONTENT
                                                Add_Raster $FILE_TO_IMPORT $MAP_NAME
                                fi
                        else
                            Close_Process
                            exit
                    fi
        # Message: Selected map is now succesfully added to your mapset
        Send_Message m 6 add_map.5 question actions [\"OK\"]
            Request
                Close_Process
                exit
fi    

    

