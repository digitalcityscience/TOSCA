#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.1
# CityApp module
# Import OSM maps into PERMANENT mapset. Points, lines, polygons, relations are only imported. Other maps can be extracted from these in separate modules.
# To import other maps, use Add Layer module.
#
# Core module, do not modify.
#
# 2020. május 14.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/add_location
MODULE_NAME=cityapp_add_location
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/add_location
MESSAGE_SENT=~/cityapp/data_to_client
GEOSERVER=~/cityapp/geoserver_data
GRASS=~/cityapp/grass/global
MAPSET=PERMANENT

#touch $VARIABLES/launch_locked
#echo "launch_locked" > $VARIABLES/launch_locked

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
    }

#
# -- Processing ------------------------
#

    if [ $(grass -f ~/cityapp/grass/global/PERMANENT/ --exec g.list type=vector | grep lines_osm) ]
        then
            # There is an already added location, and it is not allowed to add further locations. If you want to add a new location, the already existing location will automatically removed. If you want to store the already existing location, save manually (refer to the manual, please). Do you want to add a new location? If yes, click OK.
            Send_Message m 1 add_location.1 question actions [\"Yes\",\"No\"]
                Request
                    if [ "$REQUEST_CONTENT" = "yes" -o "$REQUEST_CONTENT" = "Yes" -o "$REQUEST_CONTENT" = "YES" ]
                        then
                            rm -f $GEOSERVER/*
                            rm -fR $GRASS/$MAPSET
                            rm -fR $GRASS/module*
                            mkdir $GRASS/$MAPSET
                            cp -r ~/cityapp/grass/skel_permanent/* $GRASS/$MAPSET
                            INIT=1
                        else
                            # Exit process, click OK.
                            Send_Message m 3 add_location.3 question actions [\"OK\"]
                                Request
                                    Running_Check stop
                                    Close_Process
                                    exit
                    fi
        else
            # No valid location found. First have to add a location to the dataset. Without such location, CityApp will not work. Adding a new location may take a long time, depending on the file size. If you want to continue, click Yes.
            Send_Message m 2 add_location.2 question actions [\"Yes\",\"No\"]
                Request
                    if [ "$REQUEST_CONTENT" = "yes" -o "$REQUEST_CONTENT" = "Yes" -o "$REQUEST_CONTENT" = "YES" ]
                        then
                            INIT=1
                        else
                            # Exit process, click OK.
                            Send_Message m 3 add_location.3 question actions [\"OK\"]
                                Request
                                    Running_Check stop
                                    Close_Process
                                    exit
                    fi
    fi

case $INIT in
    "1")
        # Select a map to add to CityApp. Map has to be in Open Street Map format -- osm is the only accepted format.
        Send_Message m 4 add_location.4 upload actions [\"OK\"]
            Request_Map osm
                NEW_AREA_FILE=$REQUEST_PATH
                rm -f $GEOSERVER/*
                rm -fR $GRASS/$MAPSET
                rm -fR $GRASS/module*
                mkdir $GRASS/$MAPSET
                cp -r ~/cityapp/grass/skel_permanent/* $GRASS/$MAPSET

                Process_Check start add_map

                Add_Osm $NEW_AREA_FILE points points_osm
                Add_Osm $NEW_AREA_FILE lines lines_osm
                Add_Osm $NEW_AREA_FILE multipolygons polygons_osm
                Add_Osm $NEW_AREA_FILE other_relations relations_osm
                Gpkg_Out points_osm points
                Gpkg_Out lines_osm lines
                Gpkg_Out polygons_osm polygons

                Process_Check stop add_map

                # Copy basemaps into $GEOSERVER/saved
                # From now this directory will contains the original, unclipped maps.
                # This may useful for further operations.
                #cp $GEOSERVER/points.gpkg $GEOSERVER/saved/
                #cp $GEOSERVER/lines.gpkg $GEOSERVER/saved/
                #cp $GEOSERVER/polygons.gpkg $GEOSERVER/saved/
                rm -f $VARIABLES/location_mod
                touch $VARIABLES/location_new
                ;;
esac

# Inserting the center coordinates of the new area in the base_map.html
coordinates

# New location is set. To exit, click OK.
Send_Message m 5 add_location.5 question actions [\"OK\"]
# Updating center coordinates to the area of selection
    Request
#        rm -f $VARIABLES/launch_locked
#        touch $VARIABLES/launcher_run

        Running_Check stop


Close_Process
exit
