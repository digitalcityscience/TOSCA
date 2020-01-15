#! /bin/bash

# This module is to calculate the fastest way from "from_points" to "to_points" thru "via_points".
# The network is the road network, with user-defined average speed.
# Defining "from_points" is mandatory, "via_points" and "to_points" are optional.
# If no "to_points" are selected, the default "to_points" will used: points along the roads, calculated by the application.

CITYAPP_MODULES_DIR=~/cityapp/scripts/modules
cd

kdialog --yesno "Do you want to remove previous from/via/to points and area?"
    if [ $? -eq 0 ]
        then
            rm -f ~/cityapp/data_from_browser/from*
            rm -f ~/cityapp/data_from_browser/via*
            rm -f ~/cityapp/data_from_browser/to*
            rm -f ~/cityapp/data_from_browser/area*
            rm -f ~/cityapp/data_from_browser/data*
    fi

# Data query
    kdialog --yesnocancel "Start points are required.\n If you want to select 'start' points from the map, click -- Yes -- \n If you want to select a map containing start points, click -- No -- \n To exit click -- Cancel --"
        case $? in
            "0")
                FROM=0
                falkon $CITYAPP_MODULES_DIR/module_1/module_1_query.html
                mv ~/cityapp/data_from_browser/"$(ls -ct1 ~/cityapp/data_from_browser | head -n1)" ~/cityapp/data_from_browser/from.geojson
                echo "var from_points = " > ~/cityapp/data_from_browser/from_points.js
                cat ~/cityapp/data_from_browser/from.geojson >> ~/cityapp/data_from_browser/from_points.js;;

            "1")
                FROM=1
                FROM_MAP=$(kdialog --getexistingdirectory ~/cityapp/grass/global/project/vector/ --title "Select a start point map")
                FROM_POINT=$(echo $FROM_MAP | cut -d"/" -f$(($(echo $FROM_MAP | sed s'/\// /'g | wc -w)+1)));;
            "2")
                exit;;
        esac

    kdialog --yesnocancel "Via points are optional.\n If you want to select 'via' points from the map, click -- Yes -- \n If you want to select a map containing via points, click -- No -- \n If you do not want to use via points, click -- Cancel --"
        case $? in
            "0")
                VIA=0
                falkon $CITYAPP_MODULES_DIR/module_1/module_1_query.html
                mv ~/cityapp/data_from_browser/"$(ls -ct1 ~/cityapp/data_from_browser | head -n1)" ~/cityapp/data_from_browser/via.geojson
                echo "var via_points = " > ~/cityapp/data_from_browser/via_points.js
                cat ~/cityapp/data_from_browser/via.geojson >> ~/cityapp/data_from_browser/via_points.js;;
            "1")
                VIA=1
                VIA_MAP=$(kdialog --getexistingdirectory ~/cityapp/grass/global/project/vector/ --title "Select a via point map")
                VIA_POINT=$(echo $VIA_MAP | cut -d"/" -f$(($(echo $VIA_MAP | sed s'/\// /'g | wc -w)+1)));;
            "2")
                VIA=2;;
        esac

    kdialog --yesnocancel "Target points are required.\n If you want to select target points from the map, click -- Yes -- \n If you want to select a map containing via points, click -- No --\n If you want to use the default target points map, click -- Cancel --"
        case $? in
            "0")
                TO=0
                falkon $CITYAPP_MODULES_DIR/module_1/module_1_query.html
                mv ~/cityapp/data_from_browser/"$(ls -ct1 ~/data_from_browser | head -n1)" ~/cityapp/data_from_browser/to.geojson
                echo "var to_points = " > ~/cityapp/data_from_browser/to_points.js
                cat ~/cityapp/data_from_browser/to.geojson >> ~/cityapp/data_from_browser/to_points.js;;
            "1")
                TO=1
                TO_MAP=$(kdialog --getexistingdirectory ~/cityapp/grass/global/project/vector --title "Select a target point map")
                TO_POINT=$(echo $TO_MAP | cut -d"/" -f$(($(echo $TO_MAP | sed s'/\// /'g | wc -w)+1)));;
            "2")
                TO=2;;
        esac

    kdialog --yesnocancel "You may define non-accessible area.\n If you want to define an area interactively on the map, click -- Yes -- \n If you want to select a map containing area, click -- No --\n If you do not want to use any area, click -- Cancel --"
        case $? in
            "0")
                AREA=0
                falkon $CITYAPP_MODULES_DIR/module_1/module_1_query.html
                mv ~/cityapp/data_from_browser/"$(ls -ct1 ~/cityapp/data_from_browser | head -n1)" ~/cityapp/data_from_browser/area.geojson
                echo "var area = " > ~/cityapp/data_from_browser/area.js
                cat ~/cityapp/data_from_browser/area.geojson >> ~/cityapp/data_from_browser/area.js;;
            "1")
                AREA=1
                AREA_MAP=$(kdialog --getexistingdirectory ~/cityapp/grass/global/project/vector --title "Select an area map")
                AREA_MAP=$(echo $AREA_MAP | cut -d"/" -f$(($(echo $AREA_MAP | sed s'/\// /'g | wc -w)+1)));;
            "2")
                AREA=2;;
        esac

    # Data process

        if [ $FROM -eq 0 ]
            then
                grass ~/cityapp/grass/global/project --exec v.in.ogr -e input=~/cityapp/data_from_browser/from.geojson layer=from output=from_point --overwrite
                FROM_POINT="from_point"
        fi

        if [ $VIA -eq 0 ]
            then
                grass ~/cityapp/grass/global/project --exec v.in.ogr -e input=~/cityapp/data_from_browser/via.geojson layer=via output=via_point --overwrite
                VIA_POINT="via_point"
        fi

        case $TO in
            "0")
                grass ~/cityapp/grass/global/project --exec v.in.ogr -e input=~/cityapp/data_from_browser/to.geojson layer=to output=to_point --overwrite
                TO_POINT="to_point";;
            "2")
                # User selected default to points (points along the roads)
                # Creating a new map, containing points along the roads
                grass ~/cityapp/grass/global/project --exec v.to.points input=clipped_lines_highway output=points_on_roads dmax=0.001 --overwrite;;
        esac

        case $AREA in
            "0")
                grass ~/cityapp/grass/global/project --exec v.in.ogr -e input=~/cityapp/data_from_browser/area.geojson layer=area output=area --overwrite
                AREA_MAP="area"

                # Clip roads map
                grass ~/cityapp/grass/global/project --exec v.overlay --overwrite ainput=lines_highway binput=$AREA_MAP operator=not output=clipped_lines_highway --overwrite;;
            "1")
                # Clip roads map
                grass ~/cityapp/grass/global/project --exec v.overlay --overwrite ainput=lines_highway binput=$AREA_MAP operator=not output=clipped_lines_highway --overwrite;;
        esac

# Setting region to fit the "selection" map (taken by location_selector), and resolution
grass ~/cityapp/grass/global/project --exec g.region vector=selection@PERMANENT res=$(cat ~/cityapp/scripts/shared/variables/resolution | tail -n1)

# connecting from/via/to point to the clipped network, if neccessary
# connecting from_point to clipped_lines_highway -- it is a mandatory step
grass ~/cityapp/grass/global/project --exec v.net input=clipped_lines_highway points=$FROM_POINT output=highways_from_points operation=connect threshold=0.005 --overwrite

# Supplementary have to calculate the cat id. of the new line segments, just added to the map by the v.net.
# For this end, first Grass will count lines in the base map (clipped_lines_highway), then in the new map (highways_from_points)
LINES_BEFORE=$(grass ~/cityapp/grass/global/project --exec v.info -t map=clipped_lines_highway | grep lines | cut -d"=" -f2)
LINES_AFTER=$(grass ~/cityapp/grass/global/project --exec v.info -t map=highways_from_points | grep lines | cut -d"=" -f2)

if [ $LINES_BEFORE -lt $LINES_AFTER ]
    then
        CAT_SUPP_LINES=$(($LINES_BEFORE+1))
fi

# Because of the previous operations, there is no more "highway" column. Now we have to rename a_highway to highway again.
grass ~/cityapp/grass/global/project --exec v.db.renamecolumn map=highways_from_points column=a_highway,highway

# Add "spd_average" attribute column (integer type) to the road network map (if not yet exist -- if exist Grass will skip this process)
grass ~/cityapp/grass/global/project --exec v.db.addcolumn map=highways_from_points columns='avg_speed INT'

# Fill this new avg_speed column for each highway feature
# Values are stored in ~/cityapp/scripts/shared/variables/roads_speed
    if [ ! -f ~/cityapp/scripts/shared/variables/roads_speed ]
        then
            cp ~/cityapp/scripts/shared/variables/roads_speed_defaults ~/cityapp/scripts/shared/variables/roads_speed
    fi

    # Kdialog is used to display current speed values,
    kdialog --textinputbox "Do you want to set the speed on the road network? \n If not, the current values will used (km/h).\n If you want to change the values, you may overwrite those. \n Do not remove semicolons from the end of lines." "$(cat ~/cityapp/scripts/shared/variables/roads_speed)" 600 600 > ~/cityapp/scripts/shared/variables/roads_speed

    # The following method is not to elegant a for loop would nicer, but this solution is a bit faster. Yes, it is a property of BASH.

    ROAD_SPD_1=$(cat ~/cityapp/scripts/shared/variables/roads_speed | head -n1 | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
    ROAD_SPD_2=$(cat ~/cityapp/scripts/shared/variables/roads_speed | head -n2 | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
    ROAD_SPD_3=$(cat ~/cityapp/scripts/shared/variables/roads_speed | head -n3 | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
    ROAD_SPD_4=$(cat ~/cityapp/scripts/shared/variables/roads_speed | head -n4 | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
    ROAD_SPD_5=$(cat ~/cityapp/scripts/shared/variables/roads_speed | head -n5 | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
    ROAD_SPD_6=$(cat ~/cityapp/scripts/shared/variables/roads_speed | head -n6 | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
    ROAD_SPD_7=$(cat ~/cityapp/scripts/shared/variables/roads_speed | head -n7 | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
    ROAD_SPD_8=$(cat ~/cityapp/scripts/shared/variables/roads_speed | head -n8 | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
    ROAD_SPD_9=$(cat ~/cityapp/scripts/shared/variables/roads_speed | head -n9 | tail -n1 | cut -d":" -f2 | sed s'/ //'g)

    grass ~/cityapp/grass/global/project --exec v.db.update map=highways_from_points layer=1 column=avg_speed value=$ROAD_SPD_1 where='highway="motorway" OR highway="motorway_link"'
    grass ~/cityapp/grass/global/project --exec v.db.update map=highways_from_points layer=1 column=avg_speed value=$ROAD_SPD_2 where='highway="trunk" OR highway="trunk_link" OR highway="primary" OR highway="primary_link"'
    grass ~/cityapp/grass/global/project --exec v.db.update map=highways_from_points layer=1 column=avg_speed value=$ROAD_SPD_3 where='highway="secondary" OR highway="secondary_link"'
    grass ~/cityapp/grass/global/project --exec v.db.update map=highways_from_points layer=1 column=avg_speed value=$ROAD_SPD_4 where='highway="tertiary" OR highway="tertiary_link"'
    grass ~/cityapp/grass/global/project --exec v.db.update map=highways_from_points layer=1 column=avg_speed value=$ROAD_SPD_5 where='highway="unclassified"'
    grass ~/cityapp/grass/global/project --exec v.db.update map=highways_from_points layer=1 column=avg_speed value=$ROAD_SPD_6 where='highway="service"'
    grass ~/cityapp/grass/global/project --exec v.db.update map=highways_from_points layer=1 column=avg_speed value=$ROAD_SPD_7 where='highway="residential"'
    grass ~/cityapp/grass/global/project --exec v.db.update map=highways_from_points layer=1 column=avg_speed value=$ROAD_SPD_8 where='highway="living_street" OR highway="pedestrian"'
    grass ~/cityapp/grass/global/project --exec v.db.update map=highways_from_points layer=1 column=avg_speed value=$ROAD_SPD_9 where='highway="footway" OR highway="bridleway" OR highway="steps" OR highway="path"'

    # The elegant solution would as:
    # n=1
    # for i in $(cat ~/cityapp/scripts/shared/variables/roads_speed); do
    #     grass ~/cityapp/grass/global/project --exec v.db.update map=highways_from_points layer=1 column=avg_speed value=$(echo $i | cut -d":" -f2 | sed s'/ //'g) where="$(cat ~/cityapp/scripts/shared/variables/highway_types | head -n$n | tail -n1)"
    #     n=$(($n+1))
    # done

    # Converting clipped and connected road network map into raster format
    grass ~/cityapp/grass/global/project --exec v.to.rast input=highways_from_points output=highways_from_points use=attr attribute_column=avg_speed --overwrite

    # Now the Supplementary lines (CAT_SUPP_LINES) raster map have to be added to map highways_from_points.
    grass ~/cityapp/grass/global/project --exec v.to.rast input=highways_from_points cats=$CAT_SUPP_LINES-1000000000 output=temp use=cat --overwrite

    # Now vector zones are created around from_points (its radius is equal to the curren resolution),
    # converted into raster format, and patched to raster map 'temp' (just created in the previous step)
    # from_zones:
    v.buffer input=from_point output=from_zones distance=$(cat ~/cityapp/scripts/shared/variables/resolution | head -n3 | tail -n1) minordistance=$(cat ~/cityapp/scripts/shared/variables/resolution | head -n3 | tail -n1) --overwrite
    v.to.rast input=from_zones output=from_zones use=val --overwrite
    r.patch input=temp,from_zones output=temp_zones --overwrite

    grass ~/cityapp/grass/global/project --exec r.reclass input=temp_zones output=temp_reclassed rules=~/cityapp/scripts/shared/variables/reclass --overwrite
    grass ~/cityapp/grass/global/project --exec r.patch input=highways_from_points,temp_reclassed output=highways_from_points_full --overwrite
    grass ~/cityapp/grass/global/project --exec r.mapcalc expression="roads_friction=$(cat ~/cityapp/scripts/shared/variables/resolution | head -n3 | tail -n1)/(highways_from_points_full*1000/3600)" --overwrite
    grass ~/cityapp/grass/global/project --exec r.cost -k input=roads_friction output=time_from_to start_points=$FROM_POINT --overwrite
    grass ~/cityapp/grass/global/project --exec r.mapcalc expression="time_from_to_minutes=time_from_to/60" --overwrite

    # Growing a bit the result to get a better visualization
    # Result is now ready for to be exported to geoserver
    grass ~/cityapp/grass/global/project --exec r.grow input=time_from_to_minutes@project output=time_map radius=1.001 --overwrite
    grass ~/cityapp/grass/global/project --exec r.out.gdal input=time_map output=/home/titusz/cityapp/geoserver_data/time_map.tif format=GTiff type=Float64 --overwrite

    # display the results:
    falkon ~/cityapp/scripts/modules/module_1/module_1_result.html
exit
