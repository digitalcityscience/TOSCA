#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.3
# CityApp module
# Import OSM maps into PERMANENT mapset. Points, lines, polygons, relations are only imported. Other maps can be extracted from these in separate modules.
# To import other maps, use Add Layer module.
#
# Core module, do not modify.
#
# 2020. február 5.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/location_selector
GRASS=~/cityapp/grass/global
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/location_selector
MESSAGE_SENT=~/cityapp/data_to_client
MAPSET=PERMANENT

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

    # Replace the line in map_display.html containing the coordinates
    sed -e '245d' $MODULE/map_display.html > $MODULE/map_display_temp.html
    sed -i "245i\
    var map = new L.Map('map', {center: new L.LatLng($NORTH, $EAST), zoom: 12 }),drawnItems = L.featureGroup().addTo(map);\
    " $MODULE/map_display_temp.html
    
    mv $MODULE/map_display_temp.html $MODULE/map_display.html
    }

if [ ! -d "$GRASS/$MAPSET/" ]
    then
        # PERMANENT not found
        # Message 1 First have to add an area (such as country) to the dataset. ...
        Send_Message m 1 location_selector.1
            
            # A simle yes/no. If no, exit
            Request
            if [ "$REQUEST_CONTENT" = "no" -o "$REQUEST_CONTENT" = "No" -o "$REQUEST_CONTENT" = "NO" ]
                then
                    exit
                else
                    INIT=0
                    # Message 2 Select a map to add to CityApp
                    Send_Message m 2 location_selector.2
                
                    # The map to import
                    Request osm
                    NEW_AREA_FILE=$REQUEST_PATH
            fi
    else
        # PERMANENT found
        # Message 4 There is an already defined area. Do you want to reshape the existing selection? If do not want reshape the selection, bceause you want to replace the entire location, select No.
        Send_Message m 4 location_selector.4
        Request
            case $REQUEST_CONTENT in
                "yes" | "Yes" | "YES")
                    INIT=1
                    # Message 5 -- It is the same as Message 2
                    # Therefore the same line will used, but the message is will set to 4.
                    Send_Message m 2 location_selector.5
                        
                        Request osm
                        NEW_AREA_FILE=$REQUEST_PATH;;
                    
                "no" | "No" | "NO")
                    INIT=0;;
            esac
fi

case $INIT in
    0)
        Send_Message m 2 location_selector.6
            Request osm
                NEW_AREA_FILE=$REQUEST_PATH
                rm -f $GEOSERVER/*
                rm -fR $GRASS/$MAPSET
                rm -fR $GRASS/module*
                mkdir $GRASS/$MAPSET
                cp -r ~/cityapp/grass/skel_permanent/* $GRASS/$MAPSET

                Add_Osm $NEW_AREA_FILE points points_osm
                Add_Osm $NEW_AREA_FILE lines lines_osm
                Add_Osm $NEW_AREA_FILE multipolygons polygons_osm
                Add_Osm $NEW_AREA_FILE other_relations relations_osm
                Gpkg_Out points_osm points
                Gpkg_Out lines_osm lines
                Gpkg_Out polygons_osm polygons
                
                # Copy basemaps into $GEOSERVER/saved
                # From now this directory will contains the original, unclipped maps.
                # This may useful for further operations.
                cp $GEOSERVER/points.gpkg $GEOSERVER/saved/
                cp $GEOSERVER/lines.gpkg $GEOSERVER/saved/
                cp $GEOSERVER/polygons.gpkg $GEOSERVER/saved/
                rm -f $VARIABLES/location_mod
                touch $VARIABLES/location_new;;
    1)
        # Refine or redefine the area selection
        rm -f $VARIABLES/location_new
        touch $VARIABLES/location_mod;;
esac

if [ ! -e $GRASS/$MAPSET/vector/lines_osm ]
    then
        Send_Message m 6 location_selector.7
        # Message 6 No lines map found in PERMANET mapset, or lines map is damaged.  To resolve this error, add again your location (map) to CityApp.
        exit
fi

# Inserting the center coordinates of the new area in the location_selector.html
coordinates

# Message 7 # Now zoom to area of your interest, then use drawing tool to define your location. Next, save your selection.
Send_Message m 7 location_selector.8
    
# This geojson is the "selection" drawn by the user. Import to GRASS and export to Geoserver
Request geojson
GEOJSON_FILE=$REQUEST_PATH 
Add_Vector "$GEOJSON_FILE" selection
Gpkg_Out selection selection
    
# Message Now you can set the resolution value (in meters). The value you declare, will used by each CityApp module
# Actually, now a separate script will run

~/cityapp/scripts/maintenance/resolution_setting.sh

#
#-- Process ----------------------------
#

# Clipping the basemaps by the selection map. Results will used in the calculations and analysis
grass $GRASS/$MAPSET --exec v.clip input=polygons_osm clip=selection output=polygons --overwrite
grass $GRASS/$MAPSET --exec v.clip input=lines_osm clip=selection output=lines --overwrite
grass $GRASS/$MAPSET --exec v.clip input=relations_osm clip=selection output=relations --overwrite

# Finally, have to set Geoserver to display raster outputs (such as time_map) properly.
# For this end, first have to prepare a "fake time_map". This is a simple geotiff, a raster version of "selection" vector map.
# This will  exported to geoserver data dir as "time_map.tif".
# Now the Geoserver have to be restarted manually and from that point, rastermaps of this locations will accepted automatically.
# This process only have to repeated, when new location is created.
# First check if a new location was created, or only a refining of the current selection:

if [  $INIT -eq 0 ]
    then
        grass $GRASS/$MAPSET --exec g.region vector=selection res=$(cat ~/cityapp/scripts/shared/variables/resolution | tail -n1) 
        grass $GRASS/$MAPSET --exec v.to.rast input=selection output=m1_time_map use=val value=1 --overwrite --quiet
        grass $GRASS/$MAPSET --exec r.out.gdal input=m1_time_map output=$GEOSERVER/m1_time_map.tif format=GTiff type=Float64 --overwrite --quiet
        
        # Restarting Geoserver
        $MODULES/maintenance/restart_geoserver.sh &
fi

# Updating center coordinates to the area of selection
coordinates

Send_Message m 9 location_selector.9

Close_Process

exit
