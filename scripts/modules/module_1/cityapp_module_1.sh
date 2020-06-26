#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.61
# CityApp module
# This module is to calculate the fastest way from "from_points" to "to_points" thru "via_points".
# The network is the road network, with user-defined average speed.
# Defining "from_points" is mandatory, "via_points" and "to_points" are optional.
# If no "to_points" are selected, the default "to_points" will used: points along the roads, calculated by the application. 
# 2020. április 20.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#



cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/module_1
MODULE_NAME=cityapp_module_1
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_1
MESSAGE_SENT=~/cityapp/data_to_client
GEOSERVER=~/cityapp/geoserver_data
GRASS=~/cityapp/grass/global
MAPSET=module_1
DATE_VALUE=$(date +%Y-%m-%d" "%H":"%M)
DATE_VALUE_2=$(date +%Y_%m_%d_%H_%M)
#
#-- Default constants values for the interpolation and time calculations. Only modify when you know what is the effects of these variables -------------------
#

SMOOTH=4
TENSION=30
BASE_RESOLUTION=0.0005
AVERAGE_SPEED=40
ROAD_POINTS=0.003
CONNECT_DISTANCE=0.003

Running_Check start

#
#-- Preprocess, User communications -------------------
#
        
rm -f $MESSAGE_SENT/*

if [ ! -d $GRASS/PERMANENT ]
    then
    # check if PERMANENT mapeset exist
        # Message 6 No valid location found. Run Location selector to create a valid location
        Send_Message m 10 module_1.11 error actions [\"Ok\"]
        Close_Process
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
            
                Process_Check start map_calculations
            
                grass $GRASS/$MAPSET --exec g.copy vector=selection@PERMANENT,selection --overwrite --quiet
                grass $GRASS/$MAPSET --exec g.copy vector=lines@PERMANENT,lines --overwrite --quiet
                
                Process_Check stop map_calculations
                
            # get center coordinates from file
                EAST=$(cat $VARIABLES/coordinate_east)
                NORTH=$(cat $VARIABLES/coordinate_north)

    fi        

# Creating empty maps for ps output, if no related maps are created/selected by user:
# m1_via_points m1_to_points, m1_stricken_area
# If user would create a such map, empty maps will automatically overwritten
    v.edit map=m1_via_points tool=create
    v.edit map=m1_to_points tool=create
    v.edit map=m1_stricken_area tool=create

# Message 1 Start points are required. Do you want to draw start points on the basemap now? If yes, click Yes, then draw one or more point and click Save button. If you want to use an already existing map, select No.
    grass $GRASS/$MAPSET --exec g.list -m type=vector > $MODULE/temp_list
    Send_Message m 1 module_1.1 question actions [\"Yes\",\"No\"]
        Request
            case $REQUEST_CONTENT in
                "yes"|"Yes"|"YES")
                    Request_Map geojson GEOJSON
                        Process_Check start add_map
                        Add_Vector $REQUEST_PATH m1_from_points
                        Gpkg_Out m1_from_points m1_from_points
                        FROM_POINT=m1_from_points
                        Process_Check stop add_map
                     ;;
                "no"|"No"|"NO")
                    # Message 2 Select a map (only point maps are supported). Avilable maps are:
                    Send_Message l 2 module_1.2 select actions [\"Yes\"] $MODULE/temp_list # Waiting for a map name (map already have to exist in GRASS)
                    Request
                        FROM_POINT=$REQUEST_CONTENT;;
                "cancel"|"Cancel"|"CANCEL")
                    exit;;
            esac
        
# Message 3 Via points are optional. If you want to select 'via' points from the map, click Yes. If you want to use an already existing map, select No. If you do not want to use via points, click Cancel.
    Send_Message m 3 module_1.3 question actions [\"Yes\",\"No\",\"Cancel\"]
        Request
            case $REQUEST_CONTENT in
                "yes"|"Yes"|"YES")
                    VIA=0
                    Request_Map geojson GEOJSON
                        FRESH=$REQUEST_PATH
                        
                        Process_Check start map_calculations
                        Add_Vector $FRESH m1_via_points
                        Gpkg_Out m1_via_points m1_via_points
                        VIA_POINT=m1_via_points
                        Process_Check stop map_calculations
                        ;;
                "no"|"No"|"NO")
                    VIA=1
                    Send_Message l 2 module_1.4  select actions [\"OK\"] $MODULE/temp_list # Waiting for a map name (map already have to exist in GRASS)
                    Request
                        VIA_POINT=$REQUEST_CONTENT;;
                "cancel"|"Cancel"|"CANCEL")
                    VIA=2
                    rm -f $GEOSERVER/m1_via_points".gpkg";;
            esac
    
# Message 3 Target points are required. If you want to select target points from the map, click Yes. If you want to use an already existing map containing target points, click No. If you want to use the default target points map, click Cancel.
    Send_Message m 4 module_1.5 question actions [\"Yes\",\"No\",\"Cancel\"]
        Request
            case $REQUEST_CONTENT in
                "yes"|"Yes"|"YES")
                    TO=0
                    Request_Map geojson GEOJSON
                        FRESH=$REQUEST_PATH
                        
                        Process_Check start add_map
                        Add_Vector $FRESH m1_to_points
                        Gpkg_Out m1_to_points m1_to_points
                        TO_POINT=m1_to_points
                        Process_Check stop add_map;;
                "no"|"No"|"NO")
                    TO=1
                    Send_Message l 2 module_1.6 select actions [\"OK\"] $MODULE/temp_list # Waiting for a map name (map already have to exist in GRASS)
                    Request
                        TO_POINT=$REQUEST_CONTENT;;
                "cancel"|"Cancel"|"CANCEL")
                    TO=2
                    rm -f $GEOSERVER/m1_to_points".gpkg";;
            esac
    
# Message 4 Optionally you may define stricken area. If you want to draw area on the map, click Yes. If you want to select a map already containing area, click No. If you do not want to use any area, click Cancel.
    Send_Message m 5 module_1.7 question actions [\"Yes\",\"No\",\"Cancel\"]
        Request
            case $REQUEST_CONTENT in
                "yes"|"Yes"|"YES")
                    AREA=0
                    Request_Map geojson GEOJSON
                        FRESH=$REQUEST_PATH
                        
                        Process_Check start add_map
                        Add_Vector $FRESH m1_stricken_area
                        Gpkg_Out m1_stricken_area m1_stricken_area
                        Process_Check stop add_map
                        
                        AREA_MAP="m1_stricken_area"
                    Send_Message m 9 module_1.12 input action [\"OK\"]
                        Request
                            REDUCING_RATIO=$REQUEST_CONTENT;;
                "no"|"No"|"NO")
                    AREA=1
                    Send_Message m 6 module_1.8 select action [\"OK\"] # Waiting for a map name (map already have to exist in GRASS)
                    Request
                        AREA_MAP=$REQUEST_CONTENT
                    Send_Message m 9 module_1.12 input action [\"OK\"]
                        Request
                            REDUCING_RATIO=$REQUEST_CONTENT;;
                "cancel"|"Cancel"|"CANCEL")
                    AREA=2
                    rm -f $GEOSERVER/m1_stricken_area".gpkg";;
            esac

# Values are stores in file variables/roads_speed.
# Based on this data, reclass file is also prepared. Will later used in reclass process.
# Messages 14 Do you want to change the speed on the road network? If not, the current values will used (km/h). If you want to change the values, you may overwrite those.
    Send_Message l 7 module_1.9 question actions [\"Yes\",\"No\"] 
        Request
            case $REQUEST_CONTENT in
                "yes"|"Yes"|"YES")
                    # Message Now you can change the speed values. Current values are:
                    Send_Message l 8 module_1.10 select actions [\"OK\"] $VARIABLES/roads_speed
                        Request
                            # echo $REQUEST_CONTENT > $VARIABLES/roads_speed;;
                    # Specific value will serves as speed value for non classified elements and newly inserted connecting line segments. Speed of these features will set to speed of service roads
                    #REDUCING_RATIO=$(cat $VARIABLES/roads_speed | head -n$n | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                    ;;
                "no"|"No"|"NO")
                    ;;
            esac

#
# -- Processing --------------------------ˇ
#

Process_Check start map_calculations

# Creating highways map. This is fundamental for the further work in this module
    grass $GRASS/$MAPSET --exec v.extract input=lines@PERMANENT type=line where="highway>0" output=highways --overwrite --quiet 
    
# True data processing Setting region to fit the "selection" map (taken by location_selector), and resolution
    grass $GRASS/$MAPSET --exec g.region vector=selection@PERMANENT res=$(cat $VARIABLES/resolution | tail -n1) --overwrite

# connecting from/via/to points to the clipped network, if neccessary. Via points are optional, first have to check if user previously has selected those or not.
    grass $GRASS/$MAPSET --exec g.copy vector=$FROM_POINT,from_via_to_points --overwrite --quiet
    if [ $VIA -eq 0 -o $VIA -eq 1 ]
        then
            grass $GRASS/$MAPSET --exec v.patch input=$FROM_POINT,$VIA_POINT output=from_via_to_points --overwrite --quiet 
    fi

# "TO" points are not optional. Optional only to place them on-by-one on the map, or  selecting an already existing map. If there are no user defined/selected to_points, default points (highway_points) are used as to_points. But, because these points are on the road by its origin, therefore no further connecting is requested.
    case $TO in
        0|1)
            grass $GRASS/$MAPSET --exec v.patch input=$TO_POINT,$FROM_POINT,$VIA_POINT output=from_via_to_points --overwrite --quiet
            ;;
        2)
            grass $GRASS/$MAPSET --exec v.to.points input=highways output=highway_points dmax=$ROAD_POINTS --overwrite --quiet
            TO_POINT="highway_points"
            ;;
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
# 169 is the size of the file when only one digit is rendered to each line. Smaller values are not possible, since the minimal speed is only 0, not a negative number.
    if [ $(echo $(stat --printf="%s" $VARIABLES/roads_speed)) -lt 169 -o ! -f $VARIABLES/roads_speed ]
        then
            cp $VARIABLES/roads_speed_defaults $VARIABLES/roads_speed
        fi

# Now updating the datatable of highways_points_connected map, using "roads_speed" file to get speed data and conditions. limit is 9 -- until [ $n -gt 9 ]; do -- because the file $VARIABLES/roads_speed has 9 lines. When the number of lines changed in the file, limit value also has to be changed.
    n=1
    until [ $n -gt 9 ]; do
        grass $GRASS/$MAPSET --exec v.db.update map=highways_points_connected layer=1 column=avg_speed value=$(cat $VARIABLES/roads_speed | head -n$n | tail -n1 | cut -d":" -f2 | sed s'/ //'g) where="$(cat $VARIABLES/highway_types | head -n$n | tail -n1)"
        n=$(($n+1))
    done

# Converting clipped and connected road network map into raster format and float number
    grass $GRASS/$MAPSET --exec v.to.rast input=highways_points_connected output=highways_points_connected use=attr attribute_column=avg_speed --overwrite --quiet
    grass $GRASS/$MAPSET --exec r.mapcalc expression="highways_points_connected=float(highways_points_connected)" --overwrite --quiet
    
# Now vector zones are created around from, via and to points (its radius is equal to the curren resolution),
# converted into raster format, and patched to raster map 'temp' (just created in the previous step)
# zones:
    grass $GRASS/$MAPSET --exec v.buffer input=from_via_to_points output=from_via_to_zones distance=$(cat $VARIABLES/resolution | tail -n1) minordistance=$(cat $VARIABLES/resolution | tail -n1) --overwrite --quiet 
    grass $GRASS/$MAPSET --exec r.mapcalc expression="from_via_to_zones=float(from_via_to_zones)" --overwrite --quiet
    grass $GRASS/$MAPSET --exec v.to.rast input=from_via_to_zones output=from_via_to_zones use=val val=$AVERAGE_SPEED --overwrite --quiet
    grass $GRASS/$MAPSET --exec r.patch input=highways_points_connected,from_via_to_zones output=highways_points_connected_zones --overwrite --quiet

# Now the Supplementary lines (formerly CAT_SUPP_LINES) raster map have to be added to map highways_from_points. First I convert highways_points_connected into raster setting value to 0(zero). Resultant map: temp. After I patch temp and highways_points_connected, result is:highways_points_connected_temp. Now have to reclass highways_points_connected_temp, setting 0 values to the speed value of residentals
    grass $GRASS/$MAPSET --exec v.to.rast input=highways_points_connected output=temp use=val val=$AVERAGE_SPEED --overwrite --quiet
    grass $GRASS/$MAPSET --exec r.patch input=highways_points_connected_zones,temp output=highways_points_connected_temp --overwrite --quiet
    
    case $AREA in
        0|1)
            grass $GRASS/$MAPSET --exec v.to.rast input=$AREA_MAP output=$AREA_MAP use=val value=$REDUCING_RATIO --overwrite
            grass $GRASS/$MAPSET --exec r.null map=$AREA_MAP null=1 --overwrite    
            grass $GRASS/$MAPSET --exec r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*$AREA_MAP)" --overwrite --quiet
            ;;
        2)
            grass $GRASS/$MAPSET --exec r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*1)" --overwrite --quiet
            ;;
    esac
    
# specific_time here is the time requested to cross a cell, where the resolution is as defined in resolution file
    grass $GRASS/$MAPSET --exec r.mapcalc expression="specific_time=$(cat $VARIABLES/resolution | head -n3 | tail -n1)/(highways_points_connected_full*0.27777)" --overwrite --quiet 

# Calculating from -- via time map, via -- to time map and it sum. There is a NULL value replacenet too. It is neccessary, because otherwise, if one of the maps containes NULL value, NULL value cells will not considering while summarizing the maps. Therefore, before mapcalc operation, NULL has to be replaced by 0.
    if [ $VIA -eq 0 -o $VIA -eq 1 ]
        then
            grass $GRASS/$MAPSET --exec r.cost input=specific_time output=from_via_cost start_points=$FROM_POINT stop_points=$VIA_POINT --overwrite --quiet 
            grass $GRASS/$MAPSET --exec r.null map=from_via_cost null=0 --overwrite
            grass $GRASS/$MAPSET --exec r.cost input=specific_time output=via_to_cost start_points=$VIA_POINT stop_points=$TO_POINT --overwrite --quiet
            grass $GRASS/$MAPSET --exec r.null map=via_to_cost null=0 --overwrite
            grass $GRASS/$MAPSET --exec r.mapcalc expression="time_map_temp=from_via_cost+via_to_cost" --overwrite --quiet
            grass $GRASS/$MAPSET --exec r.mapcalc expression="time_map=time_map_temp/60" --overwrite --quiet
        else
            grass $GRASS/$MAPSET --exec r.cost input=specific_time output=from_to_cost start_points=$FROM_POINT stop_points=$TO_POINT --overwrite --quiet
            grass $GRASS/$MAPSET --exec r.mapcalc expression="time_map_temp=from_to_cost/60" --overwrite --quiet
            grass $GRASS/$MAPSET --exec g.rename raster=time_map_temp,m1_time_map --overwrite --quiet
    fi

    grass $GRASS/$MAPSET --exec r.null map=m1_time_map setnull=0
    grass $GRASS/$MAPSET --exec r.out.gdal input=m1_time_map output=$GEOSERVER/m1_time_map.tif format=GTiff --overwrite --quiet

# Interpolation for the entire area of selection map

    grass $GRASS/$MAPSET --exec g.region res=$BASE_RESOLUTION --overwrite
    grass $GRASS/$MAPSET --exec r.mask vector=selection --overwrite
    grass $GRASS/$MAPSET --exec v.db.addcolumn map=highway_points layer=2 columns="time DOUBLE PRECISION" --overwrite
    
    
    grass $GRASS/$MAPSET --exec v.what.rast map=highway_points@module_1 raster=m1_time_map layer=2 column=time --overwrite
    
    
    grass $GRASS/$MAPSET --exec v.surf.rst input=highway_points@module_1 layer=2 zcolumn=time where="time>0" elevation=m1_time_map_interpolated tension=$TENSION smooth=$SMOOTH nprocs=4 --overwrite 
    
    grass $GRASS/$MAPSET --exec r.out.gdal input=m1_time_map_interpolated output=$GEOSERVER/m1_time_map_interpolated.tif format=GTiff --overwrite --quiet
    
# Generating pdf output
    
    # set color for maps:
    grass $GRASS/$MAPSET --exec g.region res=$(cat $VARIABLES/resolution)
    r.colors -a map=m1_time_map color=gyr
    r.colors map=m1_time_map_interpolated color=gyr

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
    echo "Considered speed on roads:" >> $MODULE/temp_time_map_info_text
    cat $VARIABLES/roads_speed >> $MODULE/temp_time_map_info_text
    echo "" >> $MODULE/temp_time_map_info_text
    echo "Speed reduction coefficient for stricken area: $REDUCING_RATIO" >> $MODULE/temp_time_map_info_text
    
    enscript -p $MODULE/temp_time_map_info_text.ps $MODULE/temp_time_map_info_text
    ps2pdf $MODULE/temp_time_map_info_text.ps $MODULE/temp_time_map_info_text.pdf
    
    grass $GRASS/$MAPSET --exec ps.map input=$MODULE/ps_param_1 output=$MODULE/time_map_1.ps --overwrite
    grass $GRASS/$MAPSET --exec ps.map input=$MODULE/ps_param_2 output=$MODULE/time_map_2.ps --overwrite
    ps2pdf $MODULE/time_map_1.ps $MODULE/time_map_1.pdf
    ps2pdf $MODULE/time_map_2.ps $MODULE/time_map_2.pdf

    gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=$MODULE/temp_m1_results_$DATE_VALUE_2".pdf" $MODULE/temp_time_map_info_text.pdf $MODULE/time_map_1.pdf $MODULE/time_map_2.pdf
    
    mv $MODULE/temp_m1_results_$DATE_VALUE_2".pdf" ~/cityapp/saved_results/time_map_results_$DATE_VALUE_2".pdf"
    
    
Process_Check stop map_calculations

Send_Message m 12 module_1.14 question actions [\"OK\"]
    Request
        Running_Check stop
        Close_Process

exit

    
    


    
