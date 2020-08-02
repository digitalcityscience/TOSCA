#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 0.1
# CityApp module
# Listing available maps by its type
# 2020. július 28.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#



cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/listing
MODULE_NAME=cityapp_listing
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/listing
MESSAGE_SENT=~/cityapp/data_to_client
GEOSERVER=~/cityapp/geoserver_data
GRASS=~/cityapp/grass/global;
MAPSET=PERMANENT;

# Processing -------------------------------

    rm -f $MODULE/temp_*
    rm -f $MODULE/map_list
    touch $MODULE/map_list
    touch $MODULE/temp_vector_maps
    touch $MODULE/temp_base_maps
    touch $MODULE/temp_raster_maps
    for i in $(grass $GRASS/$MAPSET --exec g.list type=vector);do
        case $i in
            "lines"|"lines_osm"|"points_osm"|"polygons"|"polygons_osm"|"relations"|"relations_osm"|"selection")
                echo "- $i" >> $MODULE/temp_base_maps
                ;;
            *)
                echo "- $i" >> $MODULE/temp_vector_maps
                ;;
        esac
    done

    echo "- $(grass $GRASS/$MAPSET --exec g.list type=raster)" >> $MODULE/temp_raster_maps
    
    echo "User added vector maps" > $MODULE/map_list
    cat $MODULE/temp_vector_maps >> $MODULE/map_list
    echo "------------------\"," >> $MODULE/map_list
    echo "Raster maps" >> $MODULE/map_list
    cat $MODULE/temp_raster_maps >> $MODULE/map_list
    echo "------------------\"," >> $MODULE/map_list
    echo "Base vector maps" >> $MODULE/map_list
    cat $MODULE/temp_base_maps >> $MODULE/map_list    
    
    Send_Message l 1 listing.1 question actions [\"Ok\"] $MODULE/map_list
        Request
            Close_Process
exit
