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
        VIA_POINT="m1_via_points"
        FROM_POINT="m1b_points"

        REDUCING_RATIO=$(cat $MODULES/variable_values | head -n1 | tail -n1)
        VIA=$(cat $MODULES/variable_values | head -n2 | tail -n1)
        AREA=$(cat $MODULES/variable_values | head -n3 | tail -n1)

        if [ ! -f $VARIABLES/roads_speed ]
            then
                cp $VARIABLES/roads_speed_defaults $VARIABLES/roads_speed
        fi

        TIME_LIMIT=$(cat $MODULE/time_limit)

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
        r.patch input=m1b_highways_and_points_zones,m1b_temp output=m1b_highways_and_points_temp --overwrite --quiet

    # specific_time here is the time requested to cross a cell, where the resolution is defined in resolution file
        RES_VALUE=$(cat $VARIABLES/resolution | head -n3 | tail -n1)
        r.mapcalc expression="m1b_specific_time=$RES_VALUE/(m1b_highways_and_points_temp*0.27777)" --overwrite --quiet 

    for i in $(v.db.select map=$FROM_POINT columns=cat where="cat>0");do
            v.extract cats=$i input=$FROM_POINT output=m1b_temp_point --overwrite
            r.cost input=m1b_specific_time output=m1b_cost_$i start_points=m1b_temp_point stop_points=$TO_POINT max_cost=$TIME_LIMIT --overwrite --quiet
    done
    
    #v.edit map=m1b_patch_temp tool=create
    #r.patch input=m1b_cost_4,m1b_temp output=m1b_temp --overwrite

    r.mapcalc expression="m1b_summed_maps_temp=0" --overwrite
    for i in $(g.list type=raster pattern=m1b_cost_*);do
        r.reclass input=$i output=m1b_reclassed_temp_$i rules=$MODULE/reclass_rule --overwrite
        r.mapcalc expression="m1b_reclassed_$i=m1b_reclassed_temp_$i*1" --overwrite
        r.null map=m1b_reclassed_$i null=0
        r.mapcalc expression="m1b_summed_maps_temp=m1b_reclassed_$i+m1b_summed_maps_temp" --overwrite
        #r.patch input=m1b_reclassed_$i,m1b_patch_temp output=m1b_patch_temp --overwrite
    done
        r.null map=m1b_summed_maps_temp setnull=0

exit

                # olvassuk ki VIA pont értékét
                VIA_VALUE=$(r.what map=m1a_from_to_cost points=$VIA_POINT | cut -d"|" -f4)


#--------------------------------------------
            
    r.null map=m1a_from_to_cost null=0 --overwrite
    r.cost input=m1a_specific_time output=m1a_via_to_cost start_points=$VIA_POINT stop_points=$TO_POINT --overwrite --quiet
    r.null map=m1a_via_to_cost --overwrite
    r.mapcalc expression="m1a_time_map_temp=m1a_via_to_cost+$VIA_VALUE" --overwrite --quiet
    r.mapcalc expression="m1a_time_map=m1a_time_map_temp/60" --overwrite --quiet

    exit
