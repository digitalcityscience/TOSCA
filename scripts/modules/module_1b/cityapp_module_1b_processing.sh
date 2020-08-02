#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 0.1
# CityApp module


# 2020. július 26.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules;
MODULE=~/cityapp/scripts/modules/module_1b;
MODULE_NAME=cityapp_module_1b;
VARIABLES=~/cityapp/scripts/shared/variables;
BROWSER=~/cityapp/data_from_browser;
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang);
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_1b;
MESSAGE_SENT=~/cityapp/data_to_client;
GEOSERVER=~/cityapp/geoserver_data;
GRASS=~/cityapp/grass/global;
MAPSET=module_1;
DATE_VALUE=$(date +%Y-%m-%d" "%H":"%M);
DATE_VALUE_2=$(date +%Y_%m_%d_%H_%M);


# For testing only -----------------------------

Add_Vector ~/cityapp_related/storage/osm_files/bubaneshwar_hospitals.osm m1b_points

# Preprocesing -----------------------------

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
        FROM_POINT="m1b_points"

        MINUTES=$(cat $MODULE/variable_values | head -n1 | tail -n1)
        TIME_LIMIT=$(($MINUTES*60))
        AREA=$(cat $MODULE/variable_values | head -n2 | tail -n1)
        REDUCING_RATIO=$(cat $MODULE/variable_values | head -n3 | tail -n1)

        if [ ! -f $VARIABLES/roads_speed ]
            then
                cp $VARIABLES/roads_speed_defaults $VARIABLES/roads_speed
        fi

        rm-f $MODULE/temp_info_text
        touch $MODULE/temp_info_text

# Processing ----------------------------

    # Setting region to fit the "selection" map (taken by location_selector) and resolution
        g.region vector=selection@PERMANENT res=$(cat $VARIABLES/resolution | tail -n1) --overwrite

    # "TO" points has a default value, the points of the road network will used for. But, because these points are on the road by its origin, therefore no further connecting is requested.
        v.to.points input=highways output=m1b_highway_points dmax=$ROAD_POINTS --overwrite --quiet
        
        TO_POINT="m1b_highway_points"
        
    # threshold to connect is ~ 330 m    
        v.net input=highways points=$FROM_POINT output=m1b_highways_and_points operation=connect threshold=$CONNECT_DISTANCE --overwrite
     
    # Add "spd_average" attribute column (integer type) to the road network map (if not yet exist -- if exist GRASS will skip this process)
        v.db.addcolumn map=m1b_highways_and_points columns='avg_speed INT'

    # Now updating the datatable of highways_and_points map, using "roads_speed" file to get speed data and conditions. limit is 9 -- until [ $n -gt 9 ]; do -- because the file $VARIABLES/roads_speed has 9 lines. When the number of lines changed in the file, limit value also has to be changed.
        n=1
        until [ $n -gt 9 ]; do
            v.db.update map=m1b_highways_and_points layer=1 column=avg_speed value=$(cat $VARIABLES/roads_speed | head -n$n | tail -n1 | cut -d":" -f2 | sed s'/ //'g) where="$(cat $VARIABLES/highway_types | head -n$n | tail -n1)"
            n=$(($n+1))
        done

    # Converting clipped and connected road network map into raster format and float number
        v.extract -r input=m1b_highways_and_points where=avg_speed>0 output=m1b_temp_connections --overwrite
        v.to.rast input=m1b_temp_connections output=m1b_temp_connections use=val value=$AVERAGE_SPEED --overwrite --quiet
        v.to.rast input=m1b_highways_and_points output=m1b_highways_and_points_1 use=attr attribute_column=avg_speed --overwrite --quiet
        r.patch input=m1b_temp_connections,m1b_highways_and_points_1 output=m1b_highways_and_points --overwrite
        r.mapcalc expression="m1b_highways_and_points=float(m1b_highways_and_points)" --overwrite --quiet
        
        
        
    # Now vector zones are created around points (its radius is equal to the current resolution),
    # converted into raster format, and patched to raster map 'temp' (just created in the previous step)
    # zones:
        v.buffer input=$FROM_POINT output=m1b_from_zones distance=$(cat $VARIABLES/resolution | tail -n1) minordistance=$(cat $VARIABLES/resolution | tail -n1) --overwrite --quiet 
        r.mapcalc expression="m1b_from_zones=float(m1b_from_zones)" --overwrite --quiet
        v.to.rast input=m1b_from_zones output=m1b_from_zones use=val val=$AVERAGE_SPEED --overwrite --quiet
        r.patch input=m1b_highways_and_points,m1b_from_zones output=m1b_highways_and_points_zones --overwrite --quiet

    # Now the Supplementary lines (formerly CAT_SUPP_LINES) raster map have to be added to map highways_from_points. First I convert highways_and_points into raster setting value to 0(zero). Resultant map: temp. After I patch temp and highways_and_points, result is:highways_and_points_temp. Now have to reclass highways_and_points_temp, setting 0 values to the speed value of residentals
        v.to.rast input=m1b_highways_and_points output=m1b_temp use=val val=$AVERAGE_SPEED --overwrite --quiet

        case $AREA in
            0)
                r.patch input=m1b_highways_and_points_zones,m1b_temp output=m1b_highways_and_points_temp --overwrite --quiet
                ;;
            1)
                v.to.rast input=$AREA_MAP output=$AREA_MAP use=val value=$REDUCING_RATIO --overwrite
                r.null map=$AREA_MAP null=1
                r.patch input=m1b_highways_and_points_zones,m1b_temp output=m1b_highways_and_points_temp_base --overwrite --quiet
                r.mapcalc expression="m1b_highways_and_points_temp=m1b_highways_and_points_temp_base*$AREA_MAP" --overwrite
                ;;
        esac
        
    # specific_time here is the time requested to cross a cell, where the resolution is defined in resolution file
        RES_VALUE=$(cat $VARIABLES/resolution | head -n3 | tail -n1)
        r.mapcalc expression="m1b_specific_time=$RES_VALUE/(m1b_highways_and_points_temp*0.27777)" --overwrite --quiet 

    for i in $(v.db.select map=$FROM_POINT columns=cat where="cat > 0");do
            v.extract cats=$i input=$FROM_POINT output=m1b_temp_point --overwrite
            r.cost input=m1b_specific_time output=m1b_cost_$i start_points=m1b_temp_point stop_points=$TO_POINT max_cost=$TIME_LIMIT --overwrite --quiet
    done
    
    r.mapcalc expression="m1b_accessibility_map=0" --overwrite
    for i in $(g.list type=raster pattern=m1b_cost_*);do
        r.reclass input=$i output=m1b_reclassed_temp_$i rules=$MODULE/reclass_rule --overwrite
        r.mapcalc expression="m1b_reclassed_$i=m1b_reclassed_temp_$i*1" --overwrite
        r.null map=m1b_reclassed_$i null=0
        r.mapcalc expression="m1b_accessibility_map=m1b_reclassed_$i+m1b_accessibility_map" --overwrite
    done
        r.null map=m1b_accessibility_map setnull=0

# Pdf and gpkg output ---------------------------------

  # Converting the result into vector point format
        g.region res=$CONVERSION_RESOLUTION
        r.to.vect input=m1b_accessibility_map output=m1b_accessibility_map type=point column=data --overwrite
        v.out.ogr -s input=m1b_accessibility_map type=point output=$GEOSERVER/m1b_accessibility_map.gpkg --overwrite
        v.out.ogr -s input=m1b_points type=point output=$GEOSERVER/m1b_points.gpkg --overwrite
        
    # Generating pdf output

        # set color for maps:
            g.region res=$(cat $VARIABLES/resolution | tail -n1)
            r.colors -e map=m1b_accessibility_map file=$MODULE/colors

            echo "Date of creation: $DATE_VALUE" > $MODULE/temp_info_text
            echo "" >> $MODULE/temp_info_text
            echo "Colors on map represents the number of features" >> $MODULE/temp_info_text
            echo "which can be reached within $MINUTES minutes" >> $MODULE/temp_info_text
            echo "from he given point" >> $MODULE/temp_info_text
            echo "Features (points): yellow cross" >> $MODULE/temp_info_text
            echo "Stricken area: black line" >> $MODULE/temp_info_text
            echo "" >> $MODULE/temp_info_text
            echo "Considered speed on roads:" >> $MODULE/temp_info_text
            cat $VARIABLES/roads_speed >> $MODULE/temp_info_text
            echo "" >> $MODULE/temp_info_text
            echo "Speed reduction coefficient for stricken area: $REDUCING_RATIO" >> $MODULE/temp_info_text
            
            enscript -p $MODULE/temp_info_text.ps $MODULE/temp_info_text
            ps2pdf $MODULE/temp_info_text.ps $MODULE/temp_info_text.pdf
            
            ps.map input=$MODULE/ps_param output=$MODULE/accessibility_map.ps --overwrite
            ps2pdf $MODULE/accessibility_map.ps $MODULE/accessibility_map.pdf
            
            gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=$MODULE/temp_results_$DATE_VALUE_2".pdf" $MODULE/accessibility_map.pdf $MODULE/temp_info_text.pdf
            
            cp $MODULE/temp_results_$DATE_VALUE_2".pdf" $MESSAGE_SENT/info.pdf
            cp $MODULE/temp_results_$DATE_VALUE_2".pdf" ~/cityapp/saved_results/accessibility_map_$DATE_VALUE_2".pdf"
    
            g.remove  -f type=vector pattern=temp_*
            g.remove  -f type=vector pattern=m1a_*

exit
