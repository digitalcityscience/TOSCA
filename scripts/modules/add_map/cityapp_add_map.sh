#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.4
# CityApp module
# Adding new layers to a selected mapset
# 2020. április 10.
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

# Starting running_check. running_check requires a status file too. It's firsl line is the module name and the second line is a number. When number is "1" it is allowing to run running_check.sh. Other number will stop that.

Running_Check start
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
        #Message: Select a map to add CityApp. Only gpkg (geopackage), geojson and openstreetmap vector files and geotiff (gtif or tif) raster files are accepted. Adding a map may take a long time.
        Send_Message m 2 add_map.2 upload actions [\"Yes\"]
            Request_Map geojson GEOJSON gpkg GPKG osm OSM tif TIF tiff TIFF gtif GTIF
                if [[ $REQUEST_FILE =~ ".geojson" ]] || [[ $REQUEST_FILE =~ ".GEOJSON" ]] || [[ $REQUEST_FILE =~ ".gpkg" ]] || [[ $REQUEST_FILE =~ ".GPKG" ]] || [[ $REQUEST_FILE =~ ".osm" ]] || [[ $REQUEST_FILE =~ ".OSM" ]]
                    then
                        FILE_TO_IMPORT=$REQUEST_PATH
                        #Message: Please, define an output map name. Name can contain only english characters, numbers, or underline character. Space and other specific characters are not allowed. For first character a letter only accepted.
                        Send_Message m 3 add_map.3 input actions [\"OK\"]
                            Request
                                MAP_NAME=$REQUEST_CONTENT
                                
                                Process_Check start add_vector
                                Add_Vector $FILE_TO_IMPORT $MAP_NAME
                                Process_Check stop add_vector
                                
                fi
                if  [[ $REQUEST_FILE =~ ".tif" ]] || [[ $REQUEST_FILE =~ ".TIF" ]] || [[ $REQUEST_FILE =~ ".tiff" ]] || [[ $REQUEST_FILE =~ ".TIFF" ]] || [[ $REQUEST_FILE =~ ".gtif" ]] || [[ $REQUEST_FILE =~ ".GTIF" ]]
                    then
                        FILE_TO_IMPORT=$REQUEST_PATH
                        #Message: Please, define an output map name. Name can contain only english characters, numbers, or underline character. Space and other specific characters are not allowed. For first character a letter only accepted.
                        Send_Message m 3 add_map.3 input actions [\"OK\"]
                            Request
                                MAP_NAME=$REQUEST_CONTENT
                                
                                Process_Check start add_raster
                                Add_Raster $FILE_TO_IMPORT $MAP_NAME
                                Process_Check stop add_raster
                fi
        # Message: Selected map is now succesfully added to your mapset. Add map module now exit
        Send_Message m 4 add_map.4 question actions [\"OK\"]
            Request
                Running_Check stop
                Close_Process
        exit
fi    

    

