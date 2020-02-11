#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.21
# CityApp module
# Adding new layers to a selected mapset
# 2020. február 11.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/base/add_map
GRASS=~/cityapp/grass/global
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/add_map
MESSAGE_SENT=~/cityapp/data_to_client
MAPSET=PERMANENT

#
#-- Function -----------------------------
#

function add_vector_map
    {
    # Message 3 Select a map to add CityApp. Only gpkg (geopackage) vector files and geotiff (tif) raster files are accepted.
    Send_Message m 3 add_map.3 input actions [\"Yes\"]
        Request gpkg
            IN_FILE=$REQUEST_PATH
            
    # Message 4 Please, define an output map name.
    Send_Message m 4 add_map.4 input actions [\"Yes\"]
        Request
            OUT_MAP=$REQUEST_CONTENT
    # Check layers: if more then 1 there is in the file, ask user
    if [ $(grass -f $GRASS/$MAPSET --exec v.in.ogr -l input=$IN_FILE | wc -l) -gt 1 ]
        then
            grass -f $GRASS/$MAPSET --exec v.in.ogr -l input=$IN_FILE > $MAPSET/temp_layers
            LIST=$(cat $VARIABLES/list)

            # Message 5 More then one layer found. Select a layer (one only) you want to import. Layers:
            Send_Message l 5 add_map.5  input actions [\"Yes\"] $MAPSET/temp_layers
                Request
                    OUT_LAYER=$REQUEST_CONTENT
                    grass -f $GRASS/$MAPSET --exec v.in.ogr input=$IN_FILE layer=$OUT_LAYER output=$OUT_MAP --overwrite
        else
            grass -f $GRASS/$MAPSET --exec v.in.ogr input=$IN_FILE output=$OUT_MAP --overwrite
    fi
    # Message 6 Selected map succesfully added to mapset. Do you want to add an other map to current mapset? 
    Send_Message m 6 add_map.6 question actions [\"Yes\",\"No\"]
        Request
            DONE=$REQUEST_CONTENT
}

#
#-- Process -----------------------------------
#

rm -f $MESSAGE_SENT/*

# First chech if there is a "selection" map or not.
# If not, have to send a message to user, ask him to create first a valid location.

if [ $(grass $GRASS/$MAPSET --exec g.list type=vector | grep selection) ]
    then
        echo "ok"
    else
        # Message 1 "Selection" map not found. Before adding a new layer, first you have to define a location and a selection. For this end please, use Location Selector tool of CityApp.
        Send_Message m 1 add_map.1 error actions [\"Ok\"]
fi

# Repeat process. You may add new layers until you select "no".
until [ "$DONE" = "no" -o "$DONE" = "No" -o "$DONE" = "NO" ]; do
    # Message 2 Do you want to add a VECTOR map to CityApp mapset? If yes, click Yes, otherwise select No
    Send_Message m 2 add_map.2 question actions [\"Yes\",\"No\"]
        Request
        if [ "$REQUEST_CONTENT" = "yes" -o "$REQUEST_CONTENT" = "Yes" -o "$REQUEST_CONTENT" = "YES" ]
            then
                add_vector_map
            else
                if [ "$REQUEST_CONTENT" = "no" -o "$REQUEST_CONTENT" = "No" -o "$REQUEST_CONTENT" = "NO" ]
                    then
                        add_raster_map
                fi
        fi
done
    
exit
