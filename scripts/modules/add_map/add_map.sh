#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.2
# CityApp module
# Adding new layers to a selected mapset
# 2020. február 3.
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
    # Message 3 Select a map to add CityApp. Only gpkg (geopackage) vector files and geotiff (gtif or tif) raster files are accepted.
    Send_Message 3 add_map.3
        Request gpkg
            IN_FILE=$REQUEST_PATH
            
    # Message 4 Please, define an output map name.
    Send_Message 4 add_map.4
        Request
            OUT_MAP=$REQUEST_CONTENT
    # Check layers: if more then 1 there is in the file, ask user
    if [ $(grass -f $GRASS/$MAPSET --exec v.in.ogr -l input=$IN_FILE | wc -l) -gt 1 ]
        then
            # List (the name of layers) have to be saved in a separate file, allowing to read the list by any kind of scripts, js as well. 
            grass -f $GRASS/$MAPSET --exec v.in.ogr -l input=$IN_FILE > $VARIABLES/list
            LIST=$(cat $VARIABLES/list)
            # Message 5 More then one layer found. Select a layer (one only) you want to import. Layers:
            Send_Message 5 add_map.5
                Request
                    OUT_LAYER=$REQUEST_CONTENT
                    grass -f $GRASS/$MAPSET --exec v.in.ogr input=$IN_FILE layer=$OUT_LAYER output=$OUT_MAP --overwrite
        else
            grass -f $GRASS/$MAPSET --exec v.in.ogr input=$IN_FILE output=$OUT_MAP --overwrite
    fi
    # Message 6 Selected map succesfully added to mapset. Do you want to add an other map to current mapset? 
    Send_Message 6 add_map.6
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
        # Message 1
        Send_Message 1 add_map.1
fi

# Repeat process. You may add new layers until you select "no".
until [ "$DONE" = "no" -o "$DONE" = "No" -o "$DONE" = "NO" ]; do
    # Message 2 Raster or vector map do you want to add to CityApp mapset?
    Send_Message 2 add_map.2
        Request
        if [ "$REQUEST_CONTENT" = "vector" -o "$REQUEST_CONTENT" = "Vector" -o "$REQUEST_CONTENT" = "VECTOR" ]
            then
                add_vector_map
            else
                if [ "$REQUEST_CONTENT" = "raster" -o "$REQUEST_CONTENT" = "Raster" -o "$REQUEST_CONTENT" = "RASTER" ]
                    then
                        add_raster_map
                fi
        fi
done
    
exit
