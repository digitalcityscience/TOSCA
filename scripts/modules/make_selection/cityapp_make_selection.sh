#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.0
# CityApp module
# Import OSM maps into PERMANENT mapset. Points, lines, polygons, relations are only imported. Other maps can be extracted from these in separate modules.
# To import other maps, use Add Layer module.
#
# Core module, do not modify.
#
# 2020. május 11.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/make_selection
MODULE_NAME=cityapp_make_selection
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/make_selection
MESSAGE_SENT=~/cityapp/data_to_client
GEOSERVER=~/cityapp/geoserver_data
GRASS=~/cityapp/grass/global
MAPSET=PERMANENT

touch $VARIABLES/launch_locked
echo "launch_locked" > $VARIABLES/launch_locked

Running_Check start

#
#-- Preprocess, query ------------------
#

function coordinates
    {
        if [ $(grass $GRASS/$MAPSET --exec g.list type=vector | grep selection) ]
            then
                EAST=$(grass $GRASS/$MAPSET --exec g.region -cg vector=selection | head -n1 | cut -d"=" -f2)
                NORTH=$(grass $GRASS/$MAPSET --exec g.region -cg vector=selection | head -n2 | tail -n1 | cut -d"=" -f2)
            else
                EAST=$(grass $GRASS/$MAPSET --exec g.region -cg vector=polygons_osm | head -n1 | cut -d"=" -f2)
                NORTH=$(grass $GRASS/$MAPSET --exec g.region -cg vector=polygons_osm | head -n2 | tail -n1 | cut -d"=" -f2)
        fi

        echo $EAST > $VARIABLES/coordinate_east
        echo $NORTH > $VARIABLES/coordinate_north
    
        #Sending center coordinates as a regular message
            touch $MESSAGE_SENT/message.coordinates
            echo "{" > $MESSAGE_SENT/message.coordinates
            echo "\"lat\": $NORTH," >> $MESSAGE_SENT/message.coordinates
            echo "\"lon\": $EAST" >> $MESSAGE_SENT/message.coordinates
            echo "}" >> $MESSAGE_SENT/message.coordinates

        #{
        #"lat": 30,
        #"lon": 21
        #}
        
        
        # Replace the line in base_map.html containing the coordinates
        #cp $MODULES/base_map/base_map_template.html $MODULES/base_map/base_map.html
        
        #sed -i 's/replacethisline/var map = new L.Map('\''map'\'', {center: new L.LatLng('$NORTH', '$EAST'), zoom: 9 }),drawnItems = L.featureGroup().addTo(map);/' $MODULES/base_map/base_map.html

        rm -f ~/cityapp/webapp/app.js 
        cp ~/cityapp/webapp/app_base.js ~/cityapp/webapp/app.js 
        sed -i 's/replacelat/lat: '$NORTH',/' ~/cityapp/webapp/app.js
        sed -i 's/replacelon/lon: '$EAST',/' ~/cityapp/webapp/app.js
    }
    
# ---------------------

    if [ $(grass $GRASS/$MAPSET --exec g.list type=vector | grep lines_osm) ]
        then
            INIT=1
        else
            # PERMANENT not found
            # No valid location found. First have to add a location to the dataset. Without such location, CityApp will not work. To add a location, use Add Location menu. Now click OK to exit.
            Send_Message m 1 make_selection.1 question actions [\"OK\"]
                Request
                    Running_Check stop
                    Close_Process
                    exit                
    fi

    # Message 2 # Now zoom to area of your interest, then use drawing tool to define your location. Next, save your selection.
    Send_Message m 2 make_selection.2 question actions [\"OK\"]
        # This geojson is the "selection" drawn by the user. Import to GRASS and export to Geoserver
        Request_Map geojson GEOJSON
            GEOJSON_FILE=$REQUEST_PATH
                Process_Check start add_vector
                Add_Vector "$GEOJSON_FILE" selection
                Gpkg_Out selection selection
                Process_Check stop add_vector
            
    # Running Set resolution module

    touch $VARIABLES/subprocess
    ~/cityapp/scripts/modules/resolution_setting/cityapp_resolution_setting.sh
    rm -f $VARIABLES/subprocess

#
#-- Process ----------------------------
#

    # Refine or redefine the area selection
    rm -f $VARIABLES/location_new
    touch $VARIABLES/location_mod

    # Clipping the basemaps by the selection map. Results will used in the calculations and analysis

    Process_Check start map_calculations

    grass $GRASS/$MAPSET --exec v.clip input=polygons_osm clip=selection output=polygons --overwrite
    grass $GRASS/$MAPSET --exec v.clip input=lines_osm clip=selection output=lines --overwrite
    grass $GRASS/$MAPSET --exec v.clip input=relations_osm clip=selection output=relations --overwrite

    Process_Check stop map_calculations

    # Finally, have to set Geoserver to display raster outputs (such as time_map) properly.
    # For this end, first have to prepare a "fake time_map". This is a simple geotiff, a raster version of "selection" vector map.
    # This will  exported to geoserver data dir as "time_map.tif".
    # Now the Geoserver have to be restarted manually and from that point, rastermaps of this locations will accepted automatically.
    # This process only have to repeated, when new location is created.
    # First check if a new location was created, or only a refining of the current selection:


    Process_Check start map_calculations

    grass $GRASS/$MAPSET --exec g.region vector=selection res=$(cat ~/cityapp/scripts/shared/variables/resolution | tail -n1) 
    grass $GRASS/$MAPSET --exec v.to.rast input=selection output=m1_time_map use=val value=1 --overwrite --quiet
    grass $GRASS/$MAPSET --exec r.out.gdal input=m1_time_map output=$GEOSERVER/m1_time_map.tif format=GTiff type=Float64 --overwrite --quiet
    
    # Restarting Geoserver
    $MODULES/restart_geoserver/cityapp_restart_geoserver.sh &
    
    # Updating center coordinates to selected area
        coordinates
        kill -9 $(pgrep -f node)

        cd ~/cityapp/webapp
        node app.js &
        sleep 1s
    
    Process_Check stop map_calculations


    # Process finished, selection is saved. To process exit, click OK.
    Send_Message m 3 make_selection.3 question actions [\"OK\"]
        Request
            rm -f $VARIABLES/launch_locked
            touch $VARIABLES/launcher_run


            Running_Check stop
            Close_Process
    exit
