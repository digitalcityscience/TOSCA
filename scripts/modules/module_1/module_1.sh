#! /bin/bash
# version 1.2
# CityApp module
# This module is to calculate the fastest way from "from_points" to "to_points" thru "via_points".
# The network is the road network, with user-defined average speed.
# Defining "from_points" is mandatory, "via_points" and "to_points" are optional.
# If no "to_points" are selected, the default "to_points" will used: points along the roads, calculated by the application. 
# 2020. január 24.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
GRASS=~/cityapp/grass/global/module_1
PERMANENT=~/cityapp/grass/global/PERMANENT
MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/module_1
BUTTONS=$(cat ~/cityapp/scripts/shared/variables/lang)/module_1_buttons
# An example message:
# kdialog --yes-label "$(cat $BUTTONS | head -n1 | tail -n1)" --no-label "$(cat $BUTTONS | head -n3 | tail -n1)" --yesno "$(cat $MESSAGES | head -n1 | tail -n1)"

# Simple functions
    function add_FROM_points 
        {
        inotifywait -e close_write ~/cityapp/data_from_browser/
        FRESH=$BROWSER/$(ls -ct1 ~/cityapp/data_from_browser/ | head -n1)
        grass $GRASS --exec v.in.ogr -o input=$FRESH  output=from_points --overwrite --quiet
        grass $GRASS --exec v.out.ogr format=GPKG input=from_points output=$GEOSERVER/from_points".gpkg" --overwrite --quiet
        FROM_POINT="from_points"
        rm -f $FRESH
        touch $MODULES/module_1/module_1_query.html
        }
        
    function add_VIA_points 
        {
        inotifywait -e close_write ~/cityapp/data_from_browser/
        FRESH=$BROWSER/$(ls -ct1 ~/cityapp/data_from_browser/ | head -n1)
        grass $GRASS --exec v.in.ogr -o input=$FRESH  output=via_points --overwrite --quiet
        grass $GRASS --exec v.out.ogr format=GPKG input=via_points output=$GEOSERVER/via_points".gpkg" --overwrite --quiet
        VIA_POINT="via_points"
        rm -f $FRESH
        touch $MODULES/module_1/module_1_query.html
        }

    function add_TO_points 
        {
        inotifywait -e close_write ~/cityapp/data_from_browser/
        FRESH=$BROWSER/$(ls -ct1 ~/cityapp/data_from_browser/ | head -n1)
        grass $GRASS --exec v.in.ogr -o input=$FRESH  output=to_points --overwrite --quiet
        grass $GRASS --exec v.out.ogr format=GPKG input=to_points output=$GEOSERVER/to_points".gpkg" --overwrite --quiet
        TO_POINT="to_points"
        rm -f $FRESH
        touch $MODULES/module_1/module_1_query.html
        }
    
    function add_AREA
        {
        inotifywait -e close_write ~/cityapp/data_from_browser/
        FRESH=$BROWSER/$(ls -ct1 ~/cityapp/data_from_browser/ | head -n1)
        grass $GRASS --exec v.in.ogr -o input=$FRESH output=area --overwrite --quiet
        grass $GRASS --exec v.out.ogr format=GPKG input=area output=$GEOSERVER/area".gpkg" --overwrite --quiet
        AREA_MAP="area"
        rm -f $FRESH
        touch $MODULES/module_1/module_1_query.html
        }
    
    function select_FROM_points
        {
        FROM_MAP=$(kdialog --getexistingdirectory $GRASS/vector/ --title "$(cat $MESSAGES | head -n1 | tail -n1)")
        FROM_POINT=$(echo $FROM_MAP | cut -d"/" -f$(($(echo $FROM_MAP | sed s'/\// /'g | wc -w)+1)))
        grass $GRASS --exec v.out.ogr format=GPKG input=$FROM_POINT output=$GEOSERVER/from_points".gpkg" --overwrite --quiet
        }
        
    function select_VIA_points
        {
        VIA_MAP=$(kdialog --getexistingdirectory $GRASS/vector/ --title "$(cat $MESSAGES | head -n2 | tail -n1)")
        VIA_POINT=$(echo $VIA_MAP | cut -d"/" -f$(($(echo $VIA_MAP | sed s'/\// /'g | wc -w)+1)))
        grass $GRASS --exec v.out.ogr format=GPKG input=$VIA_POINT output=$GEOSERVER/via_points".gpkg" --overwrite --quiet
        }
        
    function select_TO_points
        {
        TO_MAP=$(kdialog --getexistingdirectory $GRASS/vector --title "$(cat $MESSAGES | head -n3 | tail -n1)")
        TO_POINT=$(echo $TO_MAP | cut -d"/" -f$(($(echo $TO_MAP | sed s'/\// /'g | wc -w)+1)))
        grass $GRASS --exec v.out.ogr format=GPKG input=$TO_POINT output=$GEOSERVER/to_points".gpkg" --overwrite --quiet
        }
    function select_AREA
        {
        AREA_FILE=$(kdialog --getexistingdirectory $GRASS/vector --title "$(cat $MESSAGES | head -n4 | tail -n1)")
        AREA_MAP=$(echo $AREA_FILE | cut -d"/" -f$(($(echo $AREA_FILE | sed s'/\// /'g | wc -w)+1)))
        grass $GRASS --exec v.out.ogr format=GPKG input=$AREA_MAP output=$GEOSERVER/area".gpkg" --overwrite --quiet
        }

# Module_1 first check if the location settings (and, therefore selection map in PERMANENT) is the same or changed since the last running
# Acknowledgement mnagement
if [ -e $VARIABLES/location_new ]
    then
        if [ -e $MODULES/module_1/ack_location_new ]
            then
                INIT=3
            else
                INIT=1
        fi
    else
        if [ -e $VARIABLES/location_mod ]
            then
                if [ -e $MODULES/module_1/ack_location_mod ]
                    then
                        INIT=3
                    else
                        INIT=2
                fi
            else
                # MESSAGE 15
                kdialog --error "$(cat $MESSAGES | head -n15 | tail -n1)"
        fi
fi


falkon ~/cityapp/scripts/modules/module_1/module_1_query.html &
sleep 3 
# Message 5
#kdialog --yesnocancel "$(cat $MESSAGES | head -n5 | tail -n1)"
case $INIT in
    1)
        FROM=0
        # Scorched earth. Removing the entire module_1 mapset and module_1 browser data directory
        rm -f $BROWSER/module_1/*
        mkdir $BROWSER/module_1
        rm -fR $GRASS
        mkdir $GRASS
        cp -r ~/cityapp/grass/skel/* $GRASS

        # Clip lines and polygons@PERMANENT mapset with the area_of_interest, defined by the user 
        # Results will stored in the "module_1" mapset
        grass $GRASS --exec g.copy vector=selection@PERMANENT,selection --overwrite --quiet
        grass $GRASS --exec g.copy vector=lines@PERMANENT,lines --overwrite --quiet
                
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

        # Data query. The user has selected option "remove all the previous calculations and data of this modul",
        # tehrefore it is neccessary to select from_points from the base map (browser)
        # Message 6
        kdialog --yesno "$(cat $MESSAGES | head -n6 | tail -n1)"
        add_FROM_points
        
        # Everithing is deleted previously, therefore the only way to define via points it is to define points on the map
        # Message 7 
        kdialog --yesno "$(cat $MESSAGES | head -n7 | tail -n1)"
        case $? in
            0)
                VIA=0
                add_VIA_points;;
            1)
                # No maps there are in the mapset, so this selection means: don't use "via" point. It is the same as option cancel around line ~175. Therefore VIA=2
                VIA=2;;
        esac
   
        # target points by user or defaults?
        # Message 8
        kdialog --yesno "$(cat $MESSAGES | head -n8 | tail -n1)"
        case $? in
            0)
                TO=0
                add_TO_points;;
            1)
                # Now "TO" value have to set TO=2. It is because, in  statement "case $TO in" (~ liine 240), default to_points are only calculated, when $TO=2.
                # Otherwise this would impossible to allow the user to select default points, when 3 options he has (yes no cancel).
                # This will when FROM!=0, see line ~190, and ~410
                TO=2;;
        esac
             
        # # Everithing is deleted previously, tehrefore the only way to define area, it is to define an area on the map
        # Message 9
        kdialog --yesno "$(cat $MESSAGES | head -n9 | tail -n1)"
        case $? in
            0)
                AREA=0
                add_AREA;;
            1)
                # No maps there are in the mapset, so this selection means: don't use area. It is the same as option cancel around line ~200. Therefore VIA=2
                AREA=2;;
        esac
            
            touch $MODULES/module_1/ack_location_new
            rm -f $MODULES/module_1/ack_location_mod;;
    
    2|3)
        # $GRASS module_1 mapset is not removed
        # It is possible to select new from, via, to points and area as well.
        # But, if there is a new selection (taken by location selctor), first have to import that
        
        if [ $INIT -eq 2 ]
            then
                # Are of area_of_interest (selection) has changed. The location -- base map -- is the same, but the selection is not.
                # Therefore selection have to imported again, and have toremove from, via, to points and area geojons and js files.
                grass $GRASS --exec g.copy vector=selection@PERMANENT,selection --overwrite --quiet
                grass $GRASS --exec g.copy vector=lines@PERMANENT,lines --overwrite --quiet
                touch $MODULES/module_1/ack_location_mod
                rm -f $MODULES/module_1/ack_location_new
        fi
        
        # Message 10 
        kdialog --yesnocancel "$(cat $MESSAGES | head -n10 | tail -n1)"
        case $? in
            0)
                FROM=0
                add_FROM_points;;
            1)
                FROM=1
                select_FROM_points;;
            2)
                exit;;
        esac
            
        # Message 11
        kdialog --yesnocancel "$(cat $MESSAGES | head -n11 | tail -n1)"
        case $? in
            0)
                VIA=0
                add_VIA_points;;
            1)
                VIA=1
                select_VIA_points;;
            2)
                VIA=2
                rm -f $GEOSERVER/via_points".gpkg";;
        esac
            
        # Message 12
        kdialog --yesnocancel "$(cat $MESSAGES | head -n12 | tail -n1)"
        case $? in
            0)
                TO=0
                add_TO_points;;
            1)
                TO=1
                select_TO_points;;
            2)
                TO=2
                rm -f $GEOSERVER/to_points".gpkg";;
        esac
            
        # Message 13
        kdialog --yesnocancel "$(cat $MESSAGES | head -n13 | tail -n1)"
        case $? in
            0)
                AREA=0
                add_AREA;;
            1)
                AREA=1
                select_AREA;;
            2)
                AREA=2
                rm -f $GEOSERVER/area".gpkg";;
        esac;;
esac

# Kdialog is used to display current speed values. Values are stores in file variables/roads_speed.
# Based on this data, reclass file is also prepared. Will later used in reclass process.
# Messages 10
kdialog --textinputbox "$(cat $MESSAGES | head -n10 | tail -n1)" "$(cat $VARIABLES/roads_speed)" 600 600 > $VARIABLES/roads_speed
cat $VARIABLES/roads_speed | sed s'/[a-z,A-Z, ,:,_]//'g > $VARIABLES/temp
echo " 0 = "$(cat $VARIABLES/roads_speed | head -n7 | tail -n1 | cut -d":" -f2 | sed s'/;//'g | sed s'/ //'g) >  $MODULES/module_1/reclass_rules_1
for i in $(cat $VARIABLES/temp);do
    echo $i"="$i >> $MODULES/module_1/reclass_rules_1
done

# Data process in GRASS
# Import, preprocess
# Creating highways map. This is fundamental for the further work in this module
grass $GRASS --exec v.extract input=lines type=line where="highway>0" output=highways --overwrite --quiet 
case $AREA in
    0)
        # Clip roads map
        grass $GRASS --exec v.overlay ainput=highways atype=line binput=$AREA_MAP operator=not output=highways_clipped --overwrite --quiet 
        grass $GRASS --exec g.rename vector=highways_clipped,highways --overwrite --quiet;;
    1)
        # Clip roads map
        grass $GRASS --exec v.overlay ainput=highways atype=line binput=$AREA_MAP operator=not output=highways_clipped --overwrite --quiet 
        grass $GRASS --exec g.rename vector=highways_clipped,highways --overwrite --quiet;;
esac
        
# True data processing
# Setting region to fit the "selection" map (taken by location_selector), and resolution
grass $GRASS --exec g.region vector=selection res=$(cat $VARIABLES/resolution | tail -n1)

# connecting from/via/to points to the clipped network, if neccessary
# Via points are optional, first have to check if user previously has selected those or not.
grass $GRASS --exec g.copy vector=$FROM_POINT,from_via_to_points --overwrite --quiet
if [ $VIA -eq 0 -o $VIA -eq 1 ]
    then
        grass $GRASS --exec v.patch input=$FROM_POINT,$VIA_POINT output=from_via_to_points --overwrite --quiet 
fi

# To points are not optional. Optional only to place them on-by-one on the map, or  selecting an already existing map.
# If there are no user defined/selected to_points, default points (highway_points) are used as to_points.
# But, because these points are on the road by its origin, therefore no further connecting is requested.
if [ $TO -eq 2 ]
    then
        grass $GRASS --exec v.to.points input=highways output=highway_points dmax=0.002 --overwrite --quiet
        TO_POINT="highway_points"
fi

grass $GRASS --exec v.patch input=$TO_POINT,$FROM_POINT,$VIA_POINT output=from_via_to_points --overwrite --quiet 
# threshold to connect is ~ 220 m
grass $GRASS --exec v.net input=highways points=from_via_to_points output=highways_points_connected operation=connect threshold=0.003 --overwrite --quiet

# Because of the previous operations, in many case, there is no more "highway" column. Now we have to rename a_highway to highway again.
# But, in some cases -- because of the differences between country datasets -- highway field io not affected,
# the original highway field remains the same. In this case it is not neccessary to rename it.
if [ $(grass $GRASS --exec db.columns table=highways | grep a_highway) ]
    then
        grass $GRASS --exec v.db.renamecolumn map=highways_points_connected column=a_highway,highway
fi

# Add "spd_average" attribute column (integer type) to the road network map (if not yet exist -- if exist Grass will skip this process)
grass $GRASS --exec v.db.addcolumn map=highways_points_connected columns='avg_speed INT'

# Fill this new avg_speed column for each highway feature
# Values are stored in $VARIABLES/roads_speed

if [ $(echo $(stat --printf="%s" $VARIABLES/roads_speed)) -eq 0 -o ! -f $VARIABLES/roads_speed ]
then
    cp $VARIABLES/roads_speed_defaults $VARIABLES/roads_speed
fi

# Now updating the datatable of highways_points_connected map, using "roads_speed" file to get speed data and conditions
# limit is 9 -- until [ $n -gt 9 ]; do -- because the file $VARIABLES/roads_speed has 9 lines.
# When the number of lines changed in the file, limit value also has to be changed.

n=1
until [ $n -gt 9 ]; do
    grass $GRASS --exec v.db.update map=highways_points_connected layer=1 column=avg_speed value=$(cat $VARIABLES/roads_speed | head -n$n | tail -n1 | cut -d":" -f2 | sed s'/ //'g) where="$(cat $VARIABLES/highway_types | head -n$n | tail -n1)"
    n=$(($n+1))
done

# Converting clipped and connected road network map into raster format
grass $GRASS --exec v.to.rast input=highways_points_connected output=highways_points_connected use=attr attribute_column=avg_speed --overwrite --quiet
    
# Now the Supplementary lines (formerly CAT_SUPP_LINES) raster map have to be added to map highways_from_points.
# First I convert highways_points_connected into raster setting value to 0(zero). Resultant map: temp
# After I patch temp and highways_points_connected, result is:highways_points_connected_temp
# Now have to reclass highways_points_connected_temp, setting 0 values to the speed value of residentals
grass $GRASS --exec v.to.rast input=highways_points_connected output=temp use=val val=0 --overwrite --quiet
grass $GRASS --exec r.patch input=highways_points_connected,temp output=highways_points_connected_temp --overwrite --quiet
grass $GRASS --exec r.reclass input=highways_points_connected_temp output=highways_points_connected rules=$MODULES/module_1/reclass_rules_1 --overwrite --quiet

# Now vector zones are created around from, via and to points (its radius is equal to the curren resolution),
# converted into raster format, and patched to raster map 'temp' (just created in the previous step)
# zones:
grass $GRASS --exec v.buffer input=from_via_to_points output=from_via_to_zones distance=$(cat $VARIABLES/resolution | tail -n1) minordistance=$(cat $VARIABLES/resolution | tail -n1) --overwrite --quiet 
grass $GRASS --exec v.to.rast input=from_via_to_zones output=from_via_to_zones use=val --overwrite --quiet
grass $GRASS --exec r.patch input=highways_points_connected,from_via_to_zones output=highways_points_connected_full --overwrite --quiet
grass $GRASS --exec r.mapcalc expression="highways_points_connected_full=float(highways_points_connected_full)" --overwrite --quiet

# specific_time here is the time requested to cross a cell, where the resolution is as defined in resolution file
grass $GRASS --exec r.mapcalc expression="specific_time=$(cat $VARIABLES/resolution | head -n3 | tail -n1)/(highways_points_connected_full*0.27777)" --overwrite --quiet 

# Calculating from -- via time map, via -- to time map and it sum.
# There is a NULL value replacenet too. It is neccessary, because otherwise, if one of the maps containes NULL value, 
# NULL value cells will not considering while summarizing the maps
# Therefore, before mapcalc operation, NULL has to be replaced by 0.
if [ $VIA -eq 0 -o $VIA -eq 1 ]
    then
        grass $GRASS --exec r.cost input=specific_time output=from_via_cost start_points=$FROM_POINT stop_points=$VIA_POINT --overwrite --quiet 
        grass $GRASS --exec r.null map=from_via_cost null=0
        grass $GRASS --exec r.cost input=specific_time output=via_to_cost start_points=$VIA_POINT stop_points=$TO_POINT --overwrite --quiet
        grass $GRASS --exec r.null map=via_to_cost null=0
        grass $GRASS --exec r.mapcalc expression="time_map_temp=from_via_cost+via_to_cost" --overwrite --quiet
        grass $GRASS --exec r.mapcalc expression="time_map=time_map_temp/60" --overwrite --quiet
    else
        grass $GRASS --exec r.cost input=specific_time output=from_to_cost start_points=$FROM_POINT stop_points=$TO_POINT --overwrite --quiet
        grass $GRASS --exec r.mapcalc expression="time_map_temp=from_to_cost/60" --overwrite --quiet
        grass $GRASS --exec g.rename raster=time_map_temp,time_map --overwrite --quiet
fi

grass $GRASS --exec r.null map=time_map setnull=0
grass $GRASS --exec r.out.gdal input=time_map output=$GEOSERVER/time_map.tif format=GTiff type=Float64 --overwrite --quiet
falkon ~/cityapp/scripts/modules/module_1/module_1_result.html &
exit
