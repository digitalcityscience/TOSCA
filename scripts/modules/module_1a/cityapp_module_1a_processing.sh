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

# Default constants values for the interpolation and time calculations. Only modify when you know what is the effects of these variables ---
    rm -f $MODULE/ps_param_1
    rm -f $MODULE/ps_param_temp
    touch $MODULE/ps_param_temp
    
    BASE_RESOLUTION=0.0005
    AVERAGE_SPEED=40
    ROAD_POINTS=0.003
    CONNECT_DISTANCE=0.003
    CONVERSION_RESOLUTION=0.0001

    AREA_MAP="m1_stricken_area"
    VIA_POINT="m1_via_points"
    FROM_POINT="m1_from_points"

    REDUCING_RATIO=$(cat $MODULE/variable_values | head -n1 | tail -n1)
    VIA=$(cat $MODULE/variable_values | head -n2 | tail -n1)
    AREA=$(cat $MODULE/variable_values | head -n3 | tail -n1)

# Preprocess for testing only

#v.in.ogr input=~/cityapp_related/storage/gpkg_files/start_2.gpkg output=m1a_from_points --overwrite
#v.in.ogr input=~/cityapp_related/storage/gpkg_files/via_2.gpkg output=m1a_via_points --overwrite
#Gpkg_Out m1a_from_points m1_from_points
#Gpkg_Out m1a_via_points m1_via_points

#v.edit map=m1a_stricken_area tool=create
#v.edit map=m1a_stricken_area_line tool=create
    
# Processing ----------------------------------------
        
    # Setting region to fit the "selection" map (taken by location_selector) and resolution
        g.region vector=selection@PERMANENT res=$(cat $VARIABLES/resolution | tail -n1) --overwrite

    # "TO" points has a default value, the points of the road network will used for. But, because these points are on the road by its origin, therefore no further connecting is requested.

        v.to.points input=highways output=m1a_highway_points dmax=$ROAD_POINTS --overwrite --quiet
        
        TO_POINT="m1a_highway_points"
        
    # threshold to connect is ~ 330 m
    
        v.net input=highways points=$FROM_POINT output=m1a_highways_from_points operation=connect threshold=$CONNECT_DISTANCE --overwrite
    # connecting from/via/to points to the clipped network, if neccessary. Via points are optional, first have to check if user previously has selected those or not.
        if [ $VIA -eq 1  ]
            then
                v.net input=highways points=$VIA_POINT output=m1a_highways_via_points operation=connect threshold=$CONNECT_DISTANCE --overwrite
                v.patch -e input=m1a_highways_via_points,m1a_highways_from_points output=m1a_highways_points_connected --overwrite --quiet 
            else
                g.rename  vector=m1a_highways_from_points,m1a_highways_points_connected
        fi

    # Add "spd_average" attribute column (integer type) to the road network map (if not yet exist -- if exist GRASS will skip this process)
        v.db.addcolumn map=m1a_highways_points_connected columns='avg_speed INT'

    # Fill this new avg_speed column for each highway feature. Values are stored in $VARIABLES/roads_speed
        if [ ! -f $VARIABLES/roads_speed ]
            then
                cp $VARIABLES/roads_speed_defaults $VARIABLES/roads_speed
            fi

    # Now updating the datatable of highways_points_connected map, using "roads_speed" file to get speed data and conditions. limit is 9 -- until [ $n -gt 9 ]; do -- because the file $VARIABLES/roads_speed has 9 lines. When the number of lines changed in the file, limit value also has to be changed.
        n=1
        until [ $n -gt 9 ]; do
            v.db.update map=m1a_highways_points_connected layer=1 column=avg_speed value=$(cat $VARIABLES/roads_speed | head -n$n | tail -n1 | cut -d":" -f2 | sed s'/ //'g) where="$(cat $VARIABLES/highway_types | head -n$n | tail -n1)"
            n=$(($n+1))
        done

    # Converting clipped and connected road network map into raster format and float number
        v.extract -r input=m1a_highways_points_connected@module_1 where=avg_speed>0 output=m1a_temp_connections --overwrite
        v.to.rast input=m1a_temp_connections output=m1a_temp_connections use=val value=$AVERAGE_SPEED --overwrite --quiet
        v.to.rast input=m1a_highways_points_connected output=m1a_highways_points_connected_1 use=attr attribute_column=avg_speed --overwrite --quiet
        r.patch input=m1a_temp_connections,m1a_highways_points_connected_1 output=m1a_highways_points_connected --overwrite
        r.mapcalc expression="m1a_highways_points_connected=float(m1a_highways_points_connected)" --overwrite --quiet
        
    # Now vector zones are created around from and via points (its radius is equal to the curren resolution),
    # converted into raster format, and patched to raster map 'temp' (just created in the previous step)
    # zones:
        v.patch -e input=$FROM_POINT,$VIA_POINT output=m1a_from_via_points --overwrite
        v.buffer input=m1a_from_via_points output=m1a_from_via_zones distance=$(cat $VARIABLES/resolution | tail -n1) minordistance=$(cat $VARIABLES/resolution | tail -n1) --overwrite --quiet 
        r.mapcalc expression="m1a_from_via_zones=float(m1a_from_via_zones)" --overwrite --quiet
        v.to.rast input=m1a_from_via_zones output=m1a_from_via_zones use=val val=$AVERAGE_SPEED --overwrite --quiet
        r.patch input=m1a_highways_points_connected,m1a_from_via_zones output=m1a_highways_points_connected_zones --overwrite --quiet

    # Now the Supplementary lines (formerly CAT_SUPP_LINES) raster map have to be added to map highways_from_points. First I convert highways_points_connected into raster setting value to 0(zero). Resultant map: temp. After I patch temp and highways_points_connected, result is:highways_points_connected_temp. Now have to reclass highways_points_connected_temp, setting 0 values to the speed value of residentals
        v.to.rast input=m1a_highways_points_connected output=m1a_temp use=val val=$AVERAGE_SPEED --overwrite --quiet
        r.patch input=m1a_highways_points_connected_zones,m1a_temp output=m1a_highways_points_connected_temp --overwrite --quiet
        
        case $AREA in
            1)
                v.to.rast input=$AREA_MAP output=$AREA_MAP use=val value=$REDUCING_RATIO --overwrite
                r.null map=$AREA_MAP null=1 --overwrite    
                r.mapcalc expression="m1a_highways_points_connected_area_temp=(m1a_highways_points_connected_temp*$AREA_MAP)" --overwrite --quiet
                ;;
            0)
                g.rename raster=m1a_highways_points_connected_temp,m1a_highways_points_connected_area_temp --overwrite --quiet
                ;;
        esac
                r.mapcalc expression="m1a_highways_points_connected_area=(m1a_highways_points_connected_area_temp*1)" --overwrite
                
    # specific_time here is the time requested to cross a cell, where the resolution is defined in resolution file
        RES_VALUE=$(cat $VARIABLES/resolution | head -n3 | tail -n1)
        r.mapcalc expression="m1a_specific_time=$RES_VALUE/(m1a_highways_points_connected_area*0.27777)" --overwrite --quiet 

    # Calculating 'from--via' time map, 'via--to' time map and it sum. There is a NULL value replacement too. It is neccessary, because otherwise, if one of the maps containes NULL value, NULL value cells will not considering while summarizing the maps. Therefore, before mapcalc operation, NULL has to be replaced by 0.
        case $VIA in
            1)
                r.cost input=m1a_specific_time output=m1a_from_to_cost start_points=$FROM_POINT stop_points=$TO_POINT --overwrite --quiet 
                # olvassuk ki VIA pont értékét
                VIA_VALUE=$(r.what map=m1a_from_to_cost points=$VIA_POINT | cut -d"|" -f4)
                
                r.null map=m1a_from_to_cost null=0 --overwrite
                r.cost input=m1a_specific_time output=m1a_via_to_cost start_points=$VIA_POINT stop_points=$TO_POINT --overwrite --quiet
                r.null map=m1a_via_to_cost --overwrite
                r.mapcalc expression="m1a_time_map_temp=m1a_via_to_cost+$VIA_VALUE" --overwrite --quiet
                r.mapcalc expression="m1a_time_map=m1a_time_map_temp/60" --overwrite --quiet
                ;;
            0)
                r.cost input=m1a_specific_time output=m1a_from_to_cost start_points=$FROM_POINT stop_points=$TO_POINT --overwrite --quiet
                r.mapcalc expression="m1a_time_map_temp=m1a_from_to_cost/60" --overwrite --quiet
                g.rename raster=m1a_time_map_temp,m1a_time_map --overwrite --quiet
                ;;
        esac

# Map output into a pdf file ----------------------
        
        case $VIA in
            1)
                echo  >> $MODULE/ps_param_temp
                echo "vpoints m1_via_points" >> $MODULE/ps_param_temp
                echo "color black" >> $MODULE/ps_param_temp
                echo "fcolor #ff77ff" >> $MODULE/ps_param_temp
                echo "symbol basic/cross3" >> $MODULE/ps_param_temp
                echo "size 10" >> $MODULE/ps_param_temp
                echo "end" >> $MODULE/ps_param_temp
                ;;
        esac
        
        case $AREA in
            1)
                # stricken area will used as a line string, therefore first convert from area to line:
                v.type input=m1_stricken_area output=m1_stricken_area_lines from_type=boundary to_type=line --overwrite
                
                echo  >> $MODULE/ps_param_temp
                echo "vlines m1_stricken_area_lines"  >> $MODULE/ps_param_temp
                echo "color #000000" >> $MODULE/ps_param_temp
                echo "width 0.4" >> $MODULE/ps_param_temp
                echo "masked n" >> $MODULE/ps_param_temp
                echo "end" >> $MODULE/ps_param_temp
                ;;
        esac
        
        if [[ $VIA -eq 1 ]] || [[ $AREA -eq 1 ]]
            then
                cp $MODULE/ps_param_base $MODULE/ps_param_1
                cat  $MODULE/ps_param_temp >> $MODULE/ps_param_1
            else
                cp $MODULE/ps_param_base $MODULE/ps_param_1
        fi

        
    # Converting the result into vector point format
        g.region res=$CONVERSION_RESOLUTION
        r.to.vect input=m1a_time_map output=m1_time_map type=point column=data --overwrite
        v.out.ogr -s input=m1_time_map@module_1 type=point output=$GEOSERVER/m1_time_map.gpkg --overwrite
        
    # Generating pdf output

        # set color for maps:
            g.region res=$(cat $VARIABLES/resolution | tail -n1)
            r.colors -e map=m1a_time_map color=gyr

            echo "Map output for time map calculations" > $MODULE/temp_time_map_info_text
            echo "" >> $MODULE/temp_time_map_info_text
            echo "Date of map creation: $DATE_VALUE" >> $MODULE/temp_time_map_info_text
            echo "" >> $MODULE/temp_time_map_info_text
            echo "Colors on map represents time in minutes" >> $MODULE/temp_time_map_info_text
            echo "Numbers of legend are time in minutes" >> $MODULE/temp_time_map_info_text
            echo "" >> $MODULE/temp_time_map_info_text
            echo "Start point: yellow cross" >> $MODULE/temp_time_map_info_text
            echo "Via point: purple cross" >> $MODULE/temp_time_map_info_text
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
            
            gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=$MODULE/temp_results_$DATE_VALUE_2".pdf" $MODULE/time_map_1.pdf $MODULE/temp_time_map_info_text.pdf
            
            cp $MODULE/temp_results_$DATE_VALUE_2".pdf" $MESSAGE_SENT/info.pdf
            cp $MODULE/temp_results_$DATE_VALUE_2".pdf" ~/cityapp/saved_results/time_map_$DATE_VALUE_2".pdf"
    
            g.remove  -f type=vector pattern=temp_*
            g.remove  -f type=vector pattern=m1a_*
    exit

