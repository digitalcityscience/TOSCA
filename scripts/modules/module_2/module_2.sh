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
# An example message:
# kdialog --yes-label "$(cat $BUTTONS | head -n1 | tail -n1)" --no-label "$(cat $BUTTONS | head -n3 | tail -n1)" --yesno "$(cat $MESSAGES | head -n1 | tail -n1)"

    function ADD_QUERY_AREA
        {
        rm -f $BROWSER/*
        falkon $MODULES/module_2/module_2_query.html &
        inotifywait -e close_write ~/cityapp/data_from_browser/
            for f in $BROWSER/*; do
            mv "$f" `echo $f | tr ' ' '_'`;
            done
        FRESH=$BROWSER/$(ls -ct1 ~/cityapp/data_from_browser/ | head -n1)
        grass $GRASS --exec v.in.ogr -o input=$FRESH  output=m2_area --overwrite --quiet
            grass $GRASS --exec v.out.ogr format=GPKG input=m2_area output=$GEOSERVER/m2_area".gpkg" --overwrite --quiet
        QUERY_AREA_MAP="m2_area"
        #rm -f $FRESH
        touch $MODULES/module_2/module_2_query.html
        }
    
    function SELECT_QUERY_MAP
        {
        AREA_FILE=$(kdialog --getexistingdirectory $GRASS/vector --title "$(cat $MESSAGES | head -n4 | tail -n1)")
        QUERY_AREA_MAP=$(echo $AREA_FILE | cut -d"/" -f$(($(echo $AREA_FILE | sed s'/\// /'g | wc -w)+1)))
        grass $GRASS --exec v.out.ogr format=GPKG input=$QUERY_AREA_MAP output=$GEOSERVER/m2_area".gpkg" --overwrite --quiet
        }

    function SET_COORDINATES
        {
        EAST=$(cat $VARIABLES/coordinate_east)
        NORTH=$(cat $VARIABLES/coordinate_north)
        # Replace the line in module_2_query.html containing the coordinates. The next 4 lines is a single expression.
        sed -e '247d' $MODULES/module_2/module_2_query.html > $MODULES/module_2/module_2_query_temp.html
        sed -i "247i\
        var map = new L.Map('map', {center: new L.LatLng($NORTH, $EAST), zoom: 12 }),drawnItems = L.featureGroup().addTo(map);\
        " $MODULES/module_2/module_2_query_temp.html
        
        mv $MODULES/module_2/module_2_query_temp.html $MODULES/module_2/module_2_query.html
        }

# Module_2 first check if the location settings (and, therefore selection map in PERMANENT) is the same or changed since the last running
# If no changes, then module_2_query.html will unchanged
# If new or modified location found, change center coordinates in module_2_query.html.
# Acknowledgement mnagement
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

kdialog --yes-label "$(cat $BUTTONS | head -n1 | tail -n1)" --no-label "$(cat $BUTTONS | head -n2 | tail -n1)" --cancel-label "$(cat $BUTTONS | head -n3 | tail -n1)" --yesnocancel "$(cat $MESSAGES | head -n2 | tail -n1)"

case $? in
    0)
        ADD_QUERY_AREA;;
    1)
        SELECT_QUERY_MAP;;
    2)
        exit;;
esac
exit
