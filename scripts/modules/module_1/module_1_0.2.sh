#! /bin/bash

# This module is to calculate the fastest way from "from_points" to "to_points" thru "via_points".
# The network is the road network, with user-defined average speed.
# Defining "from_points" is mandatory, "via_points" and "to_points" are optional.
# If no "to_points" are selected, the default "to_points" will used: points along the roads, calculated by the application.

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/module_1
# An example message:
# kdialog --yesnocancel "$(cat $MESSAGES | head -n1 | tail -n1)"

# Simple functions
    function add_FROM_points 
        {
        falkon $MODULES/module_1/module_1_query.html
        mv $BROWSER/"$(ls -ct1 $BROWSER | head -n1 | grep module_01)" $BROWSER/module_1/from.geojson
        echo "var from_points = " > $BROWSER/module_1/from_points.js
        cat $BROWSER/module_1/from.geojson >> $BROWSER/module_1/from_points.js
        }
        
    function add_VIA_points 
        {
        falkon $MODULES/module_1/module_1_query.html
        mv $BROWSER/"$(ls -ct1 $BROWSER | head -n1 | grep module_01)" $BROWSER/module_1/via.geojson
        echo "var via_points = " > $BROWSER/module_1/via_points.js
        cat $BROWSER/module_1/via.geojson >> $BROWSER/module_1/via_points.js
        }

    function add_TO_points 
        {
        falkon $MODULES/module_1/module_1_query.html
        mv $BROWSER/"$(ls -ct1 $BROWSER | head -n1 | grep module_01)" $BROWSER/module_1/to.geojson
        echo "var to_points = " > $BROWSER/module_1/to_points.js
        cat $BROWSER/module_1/to.geojson >> $BROWSER/module_1/to_points.js
        }
    
    function add_AREA
        {
        falkon $MODULES/module_1/module_1_query.html
        mv $BROWSER/"$(ls -ct1 $BROWSER | head -n1 | grep module_01)" $BROWSER/module_1/area.geojson
        echo "var area = " > $BROWSER/module_1/area.js
        cat $BROWSER/module_1/area.geojson >> $BROWSER/module_1/area.js
        }
    
    function select_FROM_points
        {
        FROM_MAP=$(kdialog --getexistingdirectory ~/cityapp/grass/global/module_1/vector/ --title "$(cat $MESSAGES | head -n1 | tail -n1)")
        FROM_POINT=$(echo $FROM_MAP | cut -d"/" -f$(($(echo $FROM_MAP | sed s'/\// /'g | wc -w)+1)))
        }
        
    function select_VIA_points
        {
        VIA_MAP=$(kdialog --getexistingdirectory ~/cityapp/grass/global/module_1/vector/ --title "$(cat $MESSAGES | head -n2 | tail -n1)")
        VIA_POINT=$(echo $VIA_MAP | cut -d"/" -f$(($(echo $VIA_MAP | sed s'/\// /'g | wc -w)+1)))
        }
        
    function select_TO_points
        {
        TO_MAP=$(kdialog --getexistingdirectory ~/cityapp/grass/global/module_1/vector --title "$(cat $MESSAGES | head -n3 | tail -n1)")
        TO_POINT=$(echo $TO_MAP | cut -d"/" -f$(($(echo $TO_MAP | sed s'/\// /'g | wc -w)+1)))
        }
    function select_AREA
        {
        AREA_MAP=$(kdialog --getexistingdirectory ~/cityapp/grass/global/module_1/vector --title "$(cat $MESSAGES | head -n4 | tail -n1)")
        AREA_MAP=$(echo $AREA_MAP | cut -d"/" -f$(($(echo $AREA_MAP | sed s'/\// /'g | wc -w)+1)))
        }
        
        
# Message 5
kdialog --yesnocancel "$(cat $MESSAGES | head -n5 | tail -n1)"
case $? in
    0)
        # Scorched earth. Removing the entire module_1 mapset and module_1 browser data directory
            rm -f $BROWSER/module_1/*
            rm -fR ~/cityapp/grass/global/module_1
            mkdir ~/cityapp/grass/global/module_1
            cp -r ~/cityapp/grass/skel/* ~/cityapp/grass/global/module_1

        # Clip the basemap (downloaded from osm and imported into PERMANENT mapset of global location in GRASS) with the area_of_interest, defined by the user
        # Results will stored in the "module_1" mapset

            for i in $(grass ~/cityapp/grass/global/module_1 --exec g.list type=vector mapset=PERMANENT); do
                grass ~/cityapp/grass/global/module_1 --exec v.clip input=$i"@PERMANENT" clip=selection@PERMANENT output=$i
            done
        
        # Exporting maps to the GEOSERVER data dir will overwrite existing maps by the new, clipped maps.
        # From now, these clipped maps will used for visualization background.
        # It is not a problem, because the unclipped, original maps are stored in the "saved" subdir.
                
            grass ~/cityapp/grass/global/module_1 --exec v.out.ogr format=GPKG input=points output=$GEOSERVER/points".gpkg" --overwrite
            grass ~/cityapp/grass/global/module_1 --exec v.out.ogr format=GPKG input=lines output=$GEOSERVER/lines".gpkg" --overwrite
            grass ~/cityapp/grass/global/module_1 --exec v.out.ogr format=GPKG input=polygons output=$GEOSERVER/polygons".gpkg" --overwrite

        # Since unclipped base files are availables in PERMANENT mepaset, it is not neccessary to store them in this mapset.
        # module_1 will use only the derivated (clipped) maps.
            grass ~/cityapp/grass/global/module_1 --exec g.remove -f type=vector name=lines,points,polygons

        # Data query
        # Because the user have selected to remove all the previous calculations and data of this modul,
        # It is neccessary to select from_points from the base map (browser)
        FROM=0
        add_FROM_points
        
        # Message 7 
        kdialog --yesnocancel "$(cat $MESSAGES | head -n7 | tail -n1)"
            case $? in
                0)
                    VIA=0
                    add_VIA_points;;
                1)
                    VIA=1
                    select_VIA_points;;
                2)
                    ;;
            esac
            
            # Message 8
            kdialog --yesnocancel "$(cat $MESSAGES | head -n8 | tail -n1)"
            case $? in
                0)
                    TO=0
                    add_TO_points;;
                1)
                    TO=1
                    select_TO_points;;
                2)
                    ;;
            esac
            
            # Message 9
            kdialog --yesnocancel "$(cat $MESSAGES | head -n9 | tail -n1)"
            case $? in
                0)
                    AREA=0
                    add_AREA;;
                1)
                    AREA=1
                    select_AREA;;
                2)
                    ;;
            esac;;
    
    1)
        # ~/cityapp/grass/global/module_1 is not removed
        # nem töröltük a mapsetet, de attól még lehet új from pontokat választani, és persze via, to pontokat és area-t is.
        
        # Message 6 
        kdialog --yesnocancel "$(cat $MESSAGES | head -n6 | tail -n1)"
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
            
        # Message 7 
        kdialog --yesnocancel "$(cat $MESSAGES | head -n7 | tail -n1)"
            case $? in
                0)
                    VIA=0
                    add_VIA_points;;
                1)
                    VIA=1
                    select_VIA_points;;
                2)
                    ;;
            esac
            
            # Message 8
            kdialog --yesnocancel "$(cat $MESSAGES | head -n8 | tail -n1)"
            case $? in
                0)
                    TO=0
                    add_TO_points;;
                1)
                    TO=1
                    select_TO_points;;
                2)
                    ;;
            esac
            
            # Message 9
            kdialog --yesnocancel "$(cat $MESSAGES | head -n9 | tail -n1)"
            case $? in
                0)
                    AREA=0
                    add_AREA;;
                1)
                    AREA=1
                    select_AREA;;
                2)
                    ;;
            esac;;
        

    2)
        # This means, the user want to exit
        exit;;
esac

# Data process in GRASS
# Import, preprocess

        case $FROM in
            0)
                grass ~/cityapp/grass/global/module_1 --exec v.in.ogr -e input=$BROWSER/module_1/from.geojson layer=from output=from_point --overwrite
                FROM_POINT="from_point";;
            1)
                # This case is already managed by function "select_FROM_points"
                ;;
            2)
                # Not possible, because of the "exit" in this case
                ;;
        esac 
            
        case $VIA in
            0)
                grass ~/cityapp/grass/global/module_1 --exec v.in.ogr -e input=$BROWSER/module_1/via.geojson layer=via output=via_point --overwrite
                VIA_POINT="via_point";;
            1)
                # This case is already managed by function "select_FROM_points"
                ;;
            2)
                # This selection means: nothing to do, no such map will used -- VIA is optional
                ;;  
        esac

        case $TO in
            0)
                grass ~/cityapp/grass/global/module_1 --exec v.in.ogr -e input=$BROWSER/module_1/to.geojson layer=to output=to_point --overwrite
                TO_POINT="to_point";;
            1)
                # This case is already managed by function "select_TO_points"
                ;;
            2)
                # User selected default "to_points" (points along the roads)
                # Creating a new map, containing points along the roads
                grass ~/cityapp/grass/global/module_1 --exec v.to.points input=clipped_lines_highway output=points_on_roads dmax=0.001 --overwrite;;
        esac

        case $AREA in
            0)
                grass ~/cityapp/grass/global/module_1 --exec v.in.ogr -e input=$BROWSER/area.geojson layer=area output=area --overwrite
                AREA_MAP="area"

                # Clip roads map
                grass ~/cityapp/grass/global/module_1 --exec v.overlay --overwrite ainput=lines_highway binput=$AREA_MAP operator=not output=clipped_lines_highway --overwrite;;
            1)
                # Clip roads map
                grass ~/cityapp/grass/global/module_1 --exec v.overlay --overwrite ainput=lines_highway binput=$AREA_MAP operator=not output=clipped_lines_highway --overwrite;;
        esac

# True data processing
        
# Setting region to fit the "selection" map (taken by location_selector), and resolution
grass ~/cityapp/grass/global/module_1 --exec g.region vector=selection res=$(cat ~/cityapp/scripts/shared/variables/resolution | tail -n1)

# connecting from/via/to points to the clipped network, if neccessary
# Via and to points are optional, first have to check if user previously has selected those or not.

grass ~/cityapp/grass/global/module_1 --exec g.copy vector=$FROM_POINT,form_via_to_points --overwrite

if [ $VIA -eq 0 -o $VIA -eq 1 ]
    then
        grass ~/cityapp/grass/global/module_1 --exec v.patch input=$FROM_POINT,$VIA_POINT output=form_via_to_points --overwrite 
fi

if [ $TO -eq 0 -o $TO -eq 1 ]
    then
        grass ~/cityapp/grass/global/module_1 --exec v.patch input=$TO_POINT,$FROM_POINT,$VIA_POINT output=form_via_to_points --overwrite 
fi

grass ~/cityapp/grass/global/module_1 --exec v.net input=clipped_lines_highway points=form_via_to_points output=highways_points_connected operation=connect threshold=0.005 --overwrite

# Supplementary have to calculate the cat id. of the new line segments, just added to the map by the v.net.
# For this end, first Grass will count lines in the base map (clipped_lines_highway), then in the new map (highways_from_points)
LINES_BEFORE=$(grass ~/cityapp/grass/global/module_1 --exec v.info -t map=clipped_lines_highway | grep lines | cut -d"=" -f2)
LINES_AFTER=$(grass ~/cityapp/grass/global/module_1 --exec v.info -t map=highways_points_connected | grep lines | cut -d"=" -f2)

if [ $LINES_BEFORE -lt $LINES_AFTER ]
    then
        CAT_SUPP_LINES=$(($LINES_BEFORE+1))
fi

# Because of the previous operations, there is no more "highway" column. Now we have to rename a_highway to highway again.
grass ~/cityapp/grass/global/module_1 --exec v.db.renamecolumn map=highways_points_connected column=a_highway,highway

# Add "spd_average" attribute column (integer type) to the road network map (if not yet exist -- if exist Grass will skip this process)
grass ~/cityapp/grass/global/module_1 --exec v.db.addcolumn map=highways_points_connected columns='avg_speed INT'

# Fill this new avg_speed column for each highway feature
# Values are stored in ~/cityapp/scripts/shared/variables/roads_speed
    if [ ! -f ~/cityapp/scripts/shared/variables/roads_speed ]
        then
            cp ~/cityapp/scripts/shared/variables/roads_speed_defaults ~/cityapp/scripts/shared/variables/roads_speed
    fi

    # Kdialog is used to display current speed values,
    # Messages 10
    kdialog --textinputbox "$(cat $MESSAGES | head -n10 | tail -n1)" "$(cat ~/cityapp/scripts/shared/variables/roads_speed)" 600 600 > ~/cityapp/scripts/shared/variables/roads_speed

    # Speed on residential roads will used to define speed for connecting lines in SUPP_LINES (see later)
    echo " * = "$(cat ~/cityapp/scripts/shared/variables/roads_speed | head -n7 | tail -n1 | cut -d":" -f2 | sed s'/;//'g | sed s'/ //'g) >  ~/cityapp/scripts/shared/variables/reclass_module_1
    echo "end" >>  ~/cityapp/scripts/shared/variables/reclass_module_1
    

# Now updating the datatable of highways_points_connected map, using "roads_speed" file to get speed data and conditions
    n=1
    for i in $(cat ~/cityapp/scripts/shared/variables/roads_speed); do
         grass ~/cityapp/grass/global/module_1 --exec v.db.update map=highways_points_connected layer=1 column=avg_speed value=$(echo $i | cut -d":" -f2 | sed s'/ //'g) where="$(cat ~/cityapp/scripts/shared/variables/highway_types | head -n$n | tail -n1)"
         n=$(($n+1))
    done

    # Converting clipped and connected road network map into raster format
    grass ~/cityapp/grass/global/module_1 --exec v.to.rast input=highways_points_connected output=highways_points_connected use=attr attribute_column=avg_speed --overwrite

    # Now the Supplementary lines (CAT_SUPP_LINES) raster map have to be added to map highways_from_points.
    grass ~/cityapp/grass/global/module_1 --exec v.to.rast input=highways_points_connected cats=$CAT_SUPP_LINES-1000000000 output=temp use=cat --overwrite

    # Now vector zones are created around from, via and to points (its radius is equal to the curren resolution),
    # converted into raster format, and patched to raster map 'temp' (just created in the previous step)
    # zones:
    grass ~/cityapp/grass/global/module_1 --exec v.buffer input=form_via_to_points output=form_via_to_zones distance=$(cat ~/cityapp/scripts/shared/variables/resolution | tail -n1) minordistance=$(cat ~/cityapp/scripts/shared/variables/resolution | tail -n1) --overwrite 
    grass ~/cityapp/grass/global/module_1 --exec v.to.rast input=form_via_to_zones output=form_via_to_zones use=val --overwrite
    grass ~/cityapp/grass/global/module_1 --exec r.patch input=temp,form_via_to_zones output=temp_zones --overwrite
    
    # Defining a speed for raster lines, converted from SUPP_LINES
    grass ~/cityapp/grass/global/module_1 --exec r.reclass input=temp_zones output=temp_reclassed rules=~/cityapp/scripts/shared/variables/reclass_module_1 --overwrite

exit
    
    grass ~/cityapp/grass/global/module_1 --exec r.patch input=highways_points_connected,temp_reclassed output=highways_points_connected_full --overwrite
    grass ~/cityapp/grass/global/module_1 --exec r.mapcalc expression="roads_friction=$(cat ~/cityapp/scripts/shared/variables/resolution | head -n3 | tail -n1)/(highways_points_connected_full*1000/3600)" --overwrite
    
    
    # First calculation: fastest way (shortest time) between from points and via points
    grass ~/cityapp/grass/global/module_1 --exec r.cost -k input=roads_friction output=time_from_via start_points=$FROM_POINT --overwrite
    grass ~/cityapp/grass/global/module_1 --exec r.mapcalc expression="time_from_to_minutes=time_from_to/60" --overwrite

    # Growing a bit the result to get a better visualization
    # Result is now ready for to be exported to geoserver
    grass ~/cityapp/grass/global/module_1 --exec r.grow input=time_from_to_minutes@project output=time_map radius=1.001 --overwrite
    grass ~/cityapp/grass/global/module_1 --exec r.out.gdal input=time_map output=/home/titusz/cityapp/geoserver_data/time_map.tif format=GTiff type=Float64 --overwrite

    # display the results:
    falkon ~/cityapp/scripts/modules/module_1/module_1_result.html
exit
