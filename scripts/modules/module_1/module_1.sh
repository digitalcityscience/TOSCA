#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.5
# CityApp module
# This module is to calculate the fastest way from "from_points" to "to_points" thru "via_points".
# The network is the road network, with user-defined average speed.
# Defining "from_points" is mandatory, "via_points" and "to_points" are optional.
# If no "to_points" are selected, the default "to_points" will used: points along the roads, calculated by the application. 
# 2020. február 8.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/module_1
GRASS=~/cityapp/grass/global
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_1
MESSAGE_SENT=~/cityapp/data_to_client
MAPSET=module_1

#
#-- Default constants values for the interpolation and time calculations. Only modify when you know what is the effects of these variables -------------------
#

SMOOTH=8
TENSION=50
BASE_RESOLUTION=0.0005
AVERAGE_SPEED=40
ROAD_POINTS=0.003
CONNECT_DISTANCE=0.003

#
#-- Preprocess, User communications -------------------
#
        
rm -f $MESSAGE_SENT/*
if [ ! -d $GRASS/PERMANENT ]
    then
    # check if PERMANENT mapeset exist
        # Message 6 No valid location found. Run Location selector to create a valid location
        Send_Message m 9 module_1.10
fi

# First overwrite the region of module_1 mapset. If no such mapset exist, create it
    if [ -d $GRASS/$MAPSET ]
        then
            # It is simpler and faster to always copy the PERMANENT WIND than to check if is it chaged or not
                cp $GRASS/PERMANENT/WIND $GRASS/$MAPSET/WIND
        else
            # Scorched earth. Brand new mapset. Everithing has to build everithing.
                mkdir $GRASS/$MAPSET
                cp -r ~/cityapp/grass/skel/* $GRASS/$MAPSET
                cp $GRASS/PERMANENT/WIND $GRASS/$MAPSET/WIND
            
            # Clip lines and polygons@PERMANENT mapset with the area_of_interest, defined by the user 
            # Results will stored in the "module_1" mapset
                grass $GRASS/$MAPSET --exec g.copy vector=selection@PERMANENT,selection --overwrite --quiet
                grass $GRASS/$MAPSET --exec g.copy vector=lines@PERMANENT,lines --overwrite --quiet
                    
            # get center coordinates from file
                EAST=$(cat $VARIABLES/coordinate_east)
                NORTH=$(cat $VARIABLES/coordinate_north)

            # Replace the line in module_1_query.html containing the coordinates. The next 4 lines is a single expression.
                sed -e '175d' $MODULES/module_1/module_1_query.html > $MODULES/module_1/module_1_query_temp.html
                sed -i "175i\
                var map = new L.Map('map', {center: new L.LatLng($NORTH, $EAST), zoom: 12 }),drawnItems = L.featureGroup().addTo(map);\
                " $MODULES/module_1/module_1_query_temp.html
                
                mv $MODULES/module_1/module_1_query_temp.html $MODULES/module_1/module_1_query.html
                
            # Now the same for the module_1_result.html
                sed -e '217d' $MODULES/module_1/module_1_result.html > $MODULES/module_1/module_1_result_temp.html
                sed -i "217i\
                var map = new L.Map('map', {center: new L.LatLng($NORTH, $EAST), zoom: 12 }),drawnItems = L.featureGroup().addTo(map);\
                " $MODULES/module_1/module_1_result_temp.html
                
                mv $MODULES/module_1/module_1_result_temp.html $MODULES/module_1/module_1_result.html
    fi        

# Message 1 Start points are required. Do you want to draw start points on the basemap now? If yes, click Yes. If you do not want to draw points, becuse you want to use an already existing map, select No. To exit this module click Cancel. Avilable maps are:
    grass $GRASS/$MAPSET --exec g.list -m type=vector > $MODULE/temp_list
    Send_Message l 1 module_1.1 $MODULE/temp_list
        Request
            case $REQUEST_CONTENT in
                "yes"|"Yes"|"YES")
                    Request geojson
                        FRESH=$REQUEST_PATH
                        Add_Vector $FRESH from_points
                        Gpkg_Out from_points from_points
                        FROM_POINT=from_points;;
                "no"|"No"|"NO")
                    Send_Message l 2 module_1.2 $MODULE/temp_list # Waiting for a map name (map already have to exist in GRASS)
                    Request
                        FROM_POINT=$REQUEST_CONTENT;;
                "cancel"|"Cancel"|"CANCEL")
                    exit;;
            esac
        
# Message 3 Via points are optional. If you want to select 'via' points from the map, click Yes. If you dont want to draw points, because you want to use an already existing ma, select No. If you do not want to use via points, click Cancel.
    Send_Message m 3 module_1.3
        Request
            case $REQUEST_CONTENT in
                "yes"|"Yes"|"YES")
                    VIA=0
                    Request geojson
                        FRESH=$REQUEST_PATH
                        Add_Vector $FRESH via_points
                        Gpkg_Out via_points via_points
                        VIA_POINT=via_points;;
                "no"|"No"|"NO")
                    VIA=1
                    Send_Message m 2 module_1.4  # Waiting for a map name (map already have to exist in GRASS)
                    Request
                        VIA_POINT=$REQUEST_CONTENT;;
                "cancel"|"Cancel"|"CANCEL")
                    VIA=2
                    rm -f $GEOSERVER/via_points".gpkg";;
            esac
    
# Message 3 Target points are required. If you want to select target points from the map, click Yes. If you do not want to draw points, because you want to use an already existing map containing via points, click No. If you want to use the default target points map, click Cancel.
    Send_Message m 4 module_1.5
        Request
            case $REQUEST_CONTENT in
                "yes"|"Yes"|"YES")
                    TO=0
                    Request geojson
                        FRESH=$REQUEST_PATH
                        Add_Vector $FRESH to_points
                        Gpkg_Out to_points to_points
                        TO_POINT=to_points;;
                "no"|"No"|"NO")
                    TO=1
                    Send_Message m 2 module_1.6  # Waiting for a map name (map already have to exist in GRASS)
                    Request
                        TO_POINT=$REQUEST_CONTENT;;
                "cancel"|"Cancel"|"CANCEL")
                    TO=2
                    rm -f $GEOSERVER/to_points".gpkg";;
            esac
    
# Message 4 Optionally you may define non-accessible area. If you want to draw area on the map, click Yes. If you do not want to draw now, because you want to select a map already containing area, click No. If you do not want to use any area, click Cancel.
    Send_Message m 5 module_1.7
        Request
            case $REQUEST_CONTENT in
                "yes"|"Yes"|"YES")
                    Request geojson
                        FRESH=$REQUEST_PATH
                        Add_Vector $FRESH area
                        Gpkg_Out area area
                        AREA_MAP="area"
                    Send_Message m 8 module_1.11
                        Request
                            REDUCING_RATIO=$REQUEST_CONTENT;;
                "no"|"No"|"NO")
                    Send_Message m 6 module_1.8  # Waiting for a map name (map already have to exist in GRASS)
                    Request
                        AREA_MAP=$REQUEST_CONTENT
                    Send_Message m 8 module_1.11
                        Request
                            REDUCING_RATIO=$REQUEST_CONTENT;;
                "cancel"|"Cancel"|"CANCEL")
                    rm -f $GEOSERVER/area".gpkg";;
            esac

# Values are stores in file variables/roads_speed.
# Based on this data, reclass file is also prepared. Will later used in reclass process.
# Messages 14 Do you want to s    echo $i"="$i >> $MODULES/module_1/reclass_rules_1et the speed on the road network? If not, the current values will used (km/h). If you want to change the values, you may overwrite those. Do not remove semicolons from the end of lines.
    Send_Message l 7 module_1.9 $VARIABLES/roads_speed
        Request
            case $REQUEST_CONTENT in
                "yes"|"Yes"|"YES")
                    Request
                        echo $REQUEST_CONTENT > $VARIABLES/roads_speed;;
                        # Specific value will servs as speed value for non classified elements and newly inserted connecting line segments. Speed of these features will set to speed of service roads
                        #REDUCING_RATIO=$(cat $VARIABLES/roads_speed | head -n$n | tail -n1 | cut -d":" -f2 | sed s'/ //'g);;
                "no"|"No"|"NO")
                    ;;
            esac
            
#
# -- Processing --------------------------
#

# Creating highways map. This is fundamental for the further work in this module
    grass $GRASS/$MAPSET --exec v.extract input=lines@PERMANENT type=line where="highway>0" output=highways --overwrite --quiet 
    
# True data processing Setting region to fit the "selection" map (taken by location_selector), and resolution
    grass $GRASS/$MAPSET --exec g.region vector=selection@PERMANENT res=$(cat $VARIABLES/resolution | tail -n1)

# connecting from/via/to points to the clipped network, if neccessary. Via points are optional, first have to check if user previously has selected those or not.
    grass $GRASS/$MAPSET --exec g.copy vector=$FROM_POINT,from_via_to_points --overwrite --quiet
    if [ $VIA -eq 0 -o $VIA -eq 1 ]
        then
            grass $GRASS/$MAPSET --exec v.patch input=$FROM_POINT,$VIA_POINT output=from_via_to_points --overwrite --quiet 
    fi

# To points are not optional. Optional only to place them on-by-one on the map, or  selecting an already existing map. If there are no user defined/selected to_points, default points (highway_points) are used as to_points. But, because these points are on the road by its origin, therefore no further connecting is requested.
    case $TO in
        0|1)
            grass $GRASS/$MAPSET --exec v.patch input=$TO_POINT,$FROM_POINT,$VIA_POINT output=from_via_to_points --overwrite --quiet;;
        2)
            grass $GRASS/$MAPSET --exec v.to.points input=highways output=highway_points dmax=$ROAD_POINTS --overwrite --quiet
            TO_POINT="highway_points";;
    esac

# threshold to connect is ~ 330 m
grass $GRASS/$MAPSET --exec v.net input=highways points=from_via_to_points output=highways_points_connected operation=connect threshold=$CONNECT_DISTANCE --overwrite --quiet

# Because of the previous operations, in many case, there is no more "highway" column. Now we have to rename a_highway to highway again.
# But, in some cases -- because of the differences between country datasets -- highway field io not affected,
# the original highway field remains the same. In this case it is not neccessary to rename it.

    if [ $(grass $GRASS/$MAPSET --exec db.columns table=highways | grep a_highway) ]
        then
            grass $GRASS/$MAPSET --exec v.db.renamecolumn map=highways_points_connected column=a_highway,highway
    fi

# Add "spd_average" attribute column (integer type) to the road network map (if not yet exist -- if exist Grass will skip this process)
    grass $GRASS/$MAPSET --exec v.db.addcolumn map=highways_points_connected columns='avg_speed INT'

# Fill this new avg_speed column for each highway feature. Values are stored in $VARIABLES/roads_speed
    if [ $(echo $(stat --printf="%s" $VARIABLES/roads_speed)) -eq 0 -o ! -f $VARIABLES/roads_speed ]
        then
            cp $VARIABLES/roads_speed_defaults $VARIABLES/roads_speed
        fi

# Now updating the datatable of highways_points_connected map, using "roads_speed" file to get speed data and conditions. limit is 9 -- until [ $n -gt 9 ]; do -- because the file $VARIABLES/roads_speed has 9 lines. When the number of lines changed in the file, limit value also has to be changed.
    n=1
    until [ $n -gt 9 ]; do
        grass $GRASS/$MAPSET --exec v.db.update map=highways_points_connected layer=1 column=avg_speed value=$(cat $VARIABLES/roads_speed | head -n$n | tail -n1 | cut -d":" -f2 | sed s'/ //'g) where="$(cat $VARIABLES/highway_types | head -n$n | tail -n1)"
        n=$(($n+1))
    done

# Converting clipped and connected road network map into raster format
    grass $GRASS/$MAPSET --exec v.to.rast input=highways_points_connected output=highways_points_connected use=attr attribute_column=avg_speed --overwrite --quiet
    
# Now the Supplementary lines (formerly CAT_SUPP_LINES) raster map have to be added to map highways_from_points. First I convert highways_points_connected into raster setting value to 0(zero). Resultant map: temp. After I patch temp and highways_points_connected, result is:highways_points_connected_temp. Now have to reclass highways_points_connected_temp, setting 0 values to the speed value of residentals
   
    grass $GRASS/$MAPSET --exec r.mapcalc expression="highways_points_connected=float(highways_points_connected)" --overwrite --quiet
    grass $GRASS/$MAPSET --exec v.to.rast input=highways_points_connected output=temp use=val val=$AVERAGE_SPEED --overwrite --quiet
    grass $GRASS/$MAPSET --exec r.patch input=highways_points_connected,temp output=highways_points_connected_temp --overwrite --quiet
    grass $GRASS/$MAPSET --exec v.to.rast input=$AREA_MAP output=$AREA_MAP use=val value=$REDUCING_RATIO --overwrite
    grass $GRASS/$MAPSET --exec r.null map=area null=1 --overwrite    
    grass $GRASS/$MAPSET --exec r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*$AREA_MAP)" --overwrite --quiet

# specific_time here is the time requested to cross a cell, where the resolution is as defined in resolution file
    grass $GRASS/$MAPSET --exec r.mapcalc expression="specific_time=$(cat $VARIABLES/resolution | head -n3 | tail -n1)/(highways_points_connected_full*0.27777)" --overwrite --quiet 

# Calculating from -- via time map, via -- to time map and it sum. There is a NULL value replacenet too. It is neccessary, because otherwise, if one of the maps containes NULL value, NULL value cells will not considering while summarizing the maps. Therefore, before mapcalc operation, NULL has to be replaced by 0.
    if [ $VIA -eq 0 -o $VIA -eq 1 ]
        then
            grass $GRASS/$MAPSET --exec r.cost input=specific_time output=from_via_cost start_points=$FROM_POINT stop_points=$VIA_POINT --overwrite --quiet 
            grass $GRASS/$MAPSET --exec r.null map=from_via_cost null=0 --overwrite
            grass $GRASS/$MAPSET --exec r.cost input=specific_time output=via_to_cost start_points=$VIA_POINT stop_points=$TO_POINT --overwrite --quiet
            grass $GRASS/$MAPSET --exec r.null map=via_to_cost null=0
            grass $GRASS/$MAPSET --exec r.mapcalc expression="time_map_temp=from_via_cost+via_to_cost" --overwrite --quiet
            grass $GRASS/$MAPSET --exec r.mapcalc expression="time_map=time_map_temp/60" --overwrite --quiet
        else
            grass $GRASS/$MAPSET --exec r.cost input=specific_time output=from_to_cost start_points=$FROM_POINT stop_points=$TO_POINT --overwrite --quiet
            grass $GRASS/$MAPSET --exec r.mapcalc expression="time_map_temp=from_to_cost/60" --overwrite --quiet
            grass $GRASS/$MAPSET --exec g.rename raster=time_map_temp,time_map --overwrite --quiet
    fi

    grass $GRASS/$MAPSET --exec r.null map=time_map setnull=0
    grass $GRASS/$MAPSET --exec r.out.gdal input=time_map output=$GEOSERVER/time_map.tif format=GTiff --overwrite --quiet

# Interpolation for the entire area of selection map

    grass $GRASS/$MAPSET --exec g.region res=$BASE_RESOLUTION
    grass $GRASS/$MAPSET --exec r.mask vector=selection
    grass $GRASS/$MAPSET --exec v.db.addcolumn map=highway_points layer=2 columns="time DOUBLE PRECISION"
    grass $GRASS/$MAPSET --exec v.what.rast map=highway_points@module_1 raster=time_map layer=2 column=time
    grass $GRASS/$MAPSET --exec v.surf.rst input=highway_points@module_1 layer=2 zcolumn=time where="time>0" elevation=time_map_interpolated tension=$TENSION smooth=$SMOOTH nprocs=4 --overwrite 
    grass $GRASS/$MAPSET --exec r.out.gdal input=time_map_interpolated output=$GEOSERVER/time_map_interpolated.tif format=GTiff --overwrite --quiet

    Close_Process

exit
