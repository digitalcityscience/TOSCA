#! /bin/bash
# version 0.1
# CityApp module
# This module is to query any existing map by a user-defined area or user-selected area map.
# 2020. január 26.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
GRASS=~/cityapp/grass/global/module_2
PERMANENT=~/cityapp/grass/global/PERMANENT
MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/module_2
BUTTONS=$(cat ~/cityapp/scripts/shared/variables/lang)/module_2_buttons

# Module_2 first check if the location settings (and, therefore selection map in PERMANENT) is the same or changed since the last running
# If no changes, then module_2_query.html will unchanged
# If new or modified location found, change center coordinates in module_2_query.html.
# Acknowledgement mnagement

if [ -e $VARIABLES/m2_lock ]
    then
        kdialog --error "Module 2 is already running \n before continue, first exit, please."
fi

if [ -e $VARIABLES/location_new ]
    then
        if [ -e $MODULES/module_2/ack_location_new ]
            then
                INIT=3
            else
                INIT=1
                # Scorched earth. Removing the entire module_1 mapset and module_1 browser data directory
                rm -f $BROWSER/module_2/*
                mkdir $BROWSER/module_2
                rm -fR $GRASS
                mkdir $GRASS
                cp -r ~/cityapp/grass/skel/* $GRASS
                
                SET_COORDINATES
                
                touch $MODULES/module_2/ack_location_new
                rm -f $MODULES/module_2/ack_location_mod
        fi
    else
        if [ -e $VARIABLES/location_mod ]
            then
                if [ -e $MODULES/module_2/ack_location_mod ]
                    then
                        INIT=3
                    else
                        INIT=2
                        SET_COORDINATES
                        touch $MODULES/module_2/ack_location_mod
                        rm -f $MODULES/module_2/ack_location_new
                fi
            else
                # MESSAGE 1
                kdialog --error "$(cat $MESSAGES | head -n1 | tail -n1)"
                exit
        fi
fi

# Case 1
# Query an area


cd $BROWSER
rm -f ./* 
touch $VARIABLES/m2_lock
#until [ $(echo $FRESH | grep exit) ];do
    inotifywait -e close_write ./
    FRESH=$BROWSER/$(ls -ct1 ./ | head -n1)
    mv $"$FRESH" ./data.geojson

    grass $GRASS --exec v.in.ogr -o input=$BROWSER/data.geojson  output=m2_area --overwrite --quiet
    grass $GRASS --exec v.out.ogr format=GPKG input=m2_area output=$GEOSERVER/m2_area".gpkg" --overwrite --quiet
    rm -f ~/cityapp/data_from_browser/* 
    for i in $(cat $MODULES/module_2/qury_this_slum_houses);do
        
        # clip centroids only from slum_houses@PERMANENT by m2_area. Result is: clipped
        # Clip now is without creating attribute table: it is a far faster way.
        # Therefore the original area elements (houses) have to be queryied by the clipped map, but this is a fast process.
        
        v.select -t --overwrite ainput=slum_houses@PERMANENT atype=point,centroid binput=m2_area@module_2 btype=point,line,boundary,centroid,area output=clipped
        
    done
#done
rm -f $VARIABLES/m2_lock
exit
