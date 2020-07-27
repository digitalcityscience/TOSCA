#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 0.1
# CityApp module
# This module is the simplest time map calculator.
# Calculate the fastest way from "from_points" to "to_points" thru "via_points".
# This module only allows to load points from interactively from the map.
# Using already existing maps is not allowed.
# The network is the road network, with user-defined average speed.
# Defining "from_points" is mandatory, "via_points" and "to_points" are optional.
# If no "to_points" are selected, the default "to_points" will used: points along the roads, calculated by the application. 
# 2020. július 26.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules;
MODULE=~/cityapp/scripts/modules/module_1a;
MODULE_NAME=cityapp_module_1a_processing;
VARIABLES=~/cityapp/scripts/shared/variables;
BROWSER=~/cityapp/data_from_browser;
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang);
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_1a;
MESSAGE_SENT=~/cityapp/data_to_client;
GEOSERVER=~/cityapp/geoserver_data;
GRASS=~/cityapp/grass/global;
MAPSET=module_1;
DATE_VALUE=$(date +%Y-%m-%d" "%H":"%M);
DATE_VALUE_2=$(date +%Y_%m_%d_%H_%M);
#
#-- Default constants values for the interpolation and time calculations. Only modify when you know what is the effects of these variables -------------------
#

SMOOTH=4
TENSION=30
BASE_RESOLUTION=0.0005
AVERAGE_SPEED=40
ROAD_POINTS=0.003
CONNECT_DISTANCE=0.003
CONVERSION_RESOLUTION=0.0001

AREA_MAP="m1_stricken_area"
VIA_POINT="m1_via_points"
FROM_POINT="m1_from_points"

REDUCING_RATIO=$(cat $MODULE/variable_values | head -n1 | tail -n1)
TO=$(cat $MODULE/variable_values | head -n2 | tail -n1)
AREA=$(cat $MODULE/variable_values | head -n3 | tail -n1)

Process_Check start map_calculations

    # Creating highways map. This is fundamental for the further work in this module
        v.extract input=lines@PERMANENT type=line where="highway>0" output=highways --overwrite --quiet 
        
    # Setting region to fit the "selection" map (taken by location_selector) and resolution
        g.region vector=selection@PERMANENT res=$(cat $VARIABLES/resolution | tail -n1) --overwrite

    # connecting from/via/to points to the clipped network, if neccessary. Via points are optional, first have to check if user previously has selected those or not.
        g.copy vector=$FROM_POINT,from_via_to_points --overwrite --quiet
        if [ $VIA -eq 0  ]
            then
                v.patch input=$FROM_POINT,$VIA_POINT output=from_via_to_points --overwrite --quiet 
        fi

    # "TO" points has a default value, the points of the road network will used for. But, because these points are on the road by its origin, therefore no further connecting is requested.

        v.to.points input=highways output=highway_points dmax=$ROAD_POINTS --overwrite --quiet
        TO_POINT="highway_points"
        
    # threshold to connect is ~ 330 m
        v.net input=highways points=from_via_to_points output=highways_points_connected operation=connect threshold=$CONNECT_DISTANCE --overwrite --quiet

    # Because of the previous operations, in many case, there is no more "highway" column. Now we have to rename a_highway to highway again.
    # But, in some cases -- because of the differences between country datasets -- highway field io not affected,
    # the original highway field remains the same. In this case it is not neccessary to rename it.

        if [ $(db.columns table=highways | grep a_highway) ]
            then
                v.db.renamecolumn map=highways_points_connected column=a_highway,highway
        fi

    # Add "spd_average" attribute column (integer type) to the road network map (if not yet exist -- if exist Grass will skip this process)
        v.db.addcolumn map=highways_points_connected columns='avg_speed INT'

    # Fill this new avg_speed column for each highway feature. Values are stored in $VARIABLES/roads_speed
    # 169 is the size of the file when only one digit is rendered to each line. Smaller values are not possible, since the minimal speed is only 0, not a negative number.
        if [ $(echo $(stat --printf="%s" $VARIABLES/roads_speed)) -lt 169 -o ! -f $VARIABLES/roads_speed ]
            then
                cp $VARIABLES/roads_speed_defaults $VARIABLES/roads_speed
            fi

    # Now updating the datatable of highways_points_connected map, using "roads_speed" file to get speed data and conditions. limit is 9 -- until [ $n -gt 9 ]; do -- because the file $VARIABLES/roads_speed has 9 lines. When the number of lines changed in the file, limit value also has to be changed.
        n=1
        until [ $n -gt 9 ]; do
            v.db.update map=highways_points_connected layer=1 column=avg_speed value=$(cat $VARIABLES/roads_speed | head -n$n | tail -n1 | cut -d":" -f2 | sed s'/ //'g) where="$(cat $VARIABLES/highway_types | head -n$n | tail -n1)"
            n=$(($n+1))
        done

    # Converting clipped and connected road network map into raster format and float number
        v.to.rast input=highways_points_connected output=highways_points_connected use=attr attribute_column=avg_speed --overwrite --quiet
        r.mapcalc expression="highways_points_connected=float(highways_points_connected)" --overwrite --quiet
        
    # Now vector zones are created around from, via and to points (its radius is equal to the curren resolution),
    # converted into raster format, and patched to raster map 'temp' (just created in the previous step)
    # zones:
        v.buffer input=from_via_to_points output=from_via_to_zones distance=$(cat $VARIABLES/resolution | tail -n1) minordistance=$(cat $VARIABLES/resolution | tail -n1) --overwrite --quiet 
        r.mapcalc expression="from_via_to_zones=float(from_via_to_zones)" --overwrite --quiet
        v.to.rast input=from_via_to_zones output=from_via_to_zones use=val val=$AVERAGE_SPEED --overwrite --quiet
        r.patch input=highways_points_connected,from_via_to_zones output=highways_points_connected_zones --overwrite --quiet

    # Now the Supplementary lines (formerly CAT_SUPP_LINES) raster map have to be added to map highways_from_points. First I convert highways_points_connected into raster setting value to 0(zero). Resultant map: temp. After I patch temp and highways_points_connected, result is:highways_points_connected_temp. Now have to reclass highways_points_connected_temp, setting 0 values to the speed value of residentals
        v.to.rast input=highways_points_connected output=temp use=val val=$AVERAGE_SPEED --overwrite --quiet
        r.patch input=highways_points_connected_zones,temp output=highways_points_connected_temp --overwrite --quiet
        
        case $AREA in
            0)
                v.to.rast input=$AREA_MAP output=$AREA_MAP use=val value=$REDUCING_RATIO --overwrite
                r.null map=$AREA_MAP null=1 --overwrite    
                r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*$AREA_MAP)" --overwrite --quiet
                ;;
            2)
                r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*1)" --overwrite --quiet
                ;;
        esac
        
    # specific_time here is the time requested to cross a cell, where the resolution is as defined in resolution file
        r.mapcalc expression="specific_time=$(cat $VARIABLES/resolution | head -n3 | tail -n1)/(highways_points_connected_full*0.27777)" --overwrite --quiet 

    # Calculating from -- via time map, via -- to time map and it sum. There is a NULL value replacenet too. It is neccessary, because otherwise, if one of the maps containes NULL value, NULL value cells will not considering while summarizing the maps. Therefore, before mapcalc operation, NULL has to be replaced by 0.
        if [ $VIA -eq 0 ]
            then
                r.cost input=specific_time output=from_via_cost start_points=$FROM_POINT stop_points=$VIA_POINT --overwrite --quiet 
                r.null map=from_via_cost null=0 --overwrite
                r.cost input=specific_time output=via_to_cost start_points=$VIA_POINT stop_points=$TO_POINT --overwrite --quiet
                r.null map=via_to_cost null=0 --overwrite
                r.mapcalc expression="time_map_temp=from_via_cost+via_to_cost" --overwrite --quiet
                r.mapcalc expression="time_map=time_map_temp/60" --overwrite --quiet
            else
                r.cost input=specific_time output=from_to_cost start_points=$FROM_POINT stop_points=$TO_POINT --overwrite --quiet
                r.mapcalc expression="time_map_temp=from_to_cost/60" --overwrite --quiet
                g.rename raster=time_map_temp,m1_time_map --overwrite --quiet
        fi

    # Converting the result into vector point format
        g.region res=$CONVERSION_RESOLUTION
        r.to.vect --overwrite input=m1_time_map output=m1_time_map type=point column=data
        v.out.ogr -s input=m1_time_map@module_1 type=point output=/home/titusz/cityapp/geoserver_data/m1_time_map.gpkg --overwrite
        
    # Generating pdf output
        # stricken area will used as a line string, therefore first convert from area to line (ps_param_1 and psparam_2 refers to a line map):
            v.type input=m1_stricken_area output=m1_stricken_area_line from_type=boundary to_type=line

        
        # set color for maps:
            g.region res=$(cat $VARIABLES/resolution | tail -n1)
            r.colors -a map=m1_time_map color=gyr

            echo "Map output for time map calculations" > $MODULE/temp_time_map_info_text
            echo "" >> $MODULE/temp_time_map_info_text
            echo "Date of map creation: $DATE_VALUE" >> $MODULE/temp_time_map_info_text
            echo "" >> $MODULE/temp_time_map_info_text
            echo "Colors on map represents time in minutes" >> $MODULE/temp_time_map_info_text
            echo "Numbers of legend are time in minutes" >> $MODULE/temp_time_map_info_text
            echo "" >> $MODULE/temp_time_map_info_text
            echo "Start point: yellow cross" >> $MODULE/temp_time_map_info_text
            echo "Via point: purple cross" >> $MODULE/temp_time_map_info_text
            echo "Target point red cross" >> $MODULE/temp_time_map_info_text
            echo "Stricken area: black line" >> $MODULE/temp_time_map_info_text
            echo "" >> $MODULE/temp_time_map_info_text
            echo "Considered speed on roads:" >> $MDOULE/temp_time_map_info_text
            cat $VARIABLES/roads_speed >> $MODULE/temp_time_map_info_text
            echo "" >> $MODULE/temp_time_map_info_text
            echo "Speed reduction coefficient for stricken area: $REDUCING_RATIO" >> $MODULE/temp_time_map_info_text
            
            enscript -p $MODULE/temp_time_map_info_text.ps $MODULE/temp_time_map_info_text
            ps2pdf $MODULE/temp_time_map_info_text.ps $MODULE/temp_time_map_info_text.pdf
            
            ps.map input=$MODULE/ps_param_1 output=$MODULE/time_map_1.ps --overwrite
            ps2pdf $MODULE/time_map_1.ps $MODULE/time_map_1.pdf
    exit
        
