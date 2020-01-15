#! /bin/bash

# Initial settings
cd
GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
VARIABLES=~/cityapp/scripts/shared/variables
# Script
# Adding country means, to add OSM data of the given country to the PERMANENT mapset, as:
    # points
    # lines
    # polygons

kdialog --yesnocancel "Now the Scene Selector will start.\n To select a scene for further examination and analysis in the Cityapp, steps are:

1.First have to add an area (such as country) to the dataset. If you do not want to add a new area, you may skip this step. If you want to add a new area, you have to know, it may take very long time, depending on the file size (see manual).

2. Zoom to the sub-area of your interest, then use Polygon drawing tool to exactly define that.

3. Save your selection, name it, define the resolution and close the window.


Now, if you are ready to add a new area to the dataset, click to -- 'Yes' --
If you only want to refine your selection, without adding a new area, click  -- 'No' --
To leave Cityapp click to -- 'Cancel' --"

#yes = 0
#no = 1
#cancel = 2

case $? in
    "0")
        NEW_AREA_FILE=$(kdialog --getopenfilename ~/ --title "Select OSM data")
        
        rm -fR ~/cityapp/grass/global/PERMANENT/
        mkdir ~/cityapp/grass/global/PERMANENT
        cp -r ~/cityapp/grass/skel_permanent/* ~/cityapp/grass/global/PERMANENT
        
        grass ~/cityapp/grass/global/PERMANENT --exec v.in.ogr -e input=$NEW_AREA_FILE layer=points output=points --overwrite
        grass ~/cityapp/grass/global/PERMANENT --exec v.in.ogr -e input=$NEW_AREA_FILE layer=lines output=lines --overwrite
        grass ~/cityapp/grass/global/PERMANENT --exec v.in.ogr -e input=$NEW_AREA_FILE layer=multipolygons output=polygons --overwrite
        grass ~/cityapp/grass/global/PERMANENT --exec v.in.ogr -e input=$NEW_AREA_FILE layer=other_relations output=relations --overwrite

        grass ~/cityapp/grass/global/PERMANENT --exec v.out.ogr format=GPKG input=points output=$GEOSERVER/points".gpkg" --overwrite
        grass ~/cityapp/grass/global/PERMANENT --exec v.out.ogr format=GPKG input=lines output=$GEOSERVER/lines".gpkg" --overwrite
        grass ~/cityapp/grass/global/PERMANENT --exec v.out.ogr format=GPKG input=polygons output=$GEOSERVER/polygons".gpkg" --overwrite
        
        # Extracting main features from the base maps
        #From points extract these elements:
        touch $VARIABLES/feature_types/point_to_geoserver
        n=$(cat $VARIABLES/feature_types/point | wc -l)
        i=1
        until [ $i -gt $n ]; do
            j=$(echo $(cat $VARIABLES/feature_types/point | head -n$i | tail -n1 | cut -d":" -f1))
            k=$(echo $(cat $VARIABLES/feature_types/point | head -n$i | tail -n1 | cut -d":" -f2))
            grass ~/cityapp/grass/global/PERMANENT --exec v.extract input=points output=points"_"$j where="$(echo $k)" --overwrite
            echo "points"_"$j" >> $VARIABLES/feature_types/point_to_geoserver
            i=$(($i+1))
        done
        
        #From lines extract these elements:
        touch $VARIABLES/feature_types/line_to_geoserver
        n=$(cat $VARIABLES/feature_types/line | wc -l)
        i=1
        until [ $i -gt $n ]; do
            j=$(echo $(cat $VARIABLES/feature_types/line | head -n$i | tail -n1 | cut -d":" -f1))
            k=$(echo $(cat $VARIABLES/feature_types/line | head -n$i | tail -n1 | cut -d":" -f2))
            grass ~/cityapp/grass/global/PERMANENT --exec v.extract input=lines output=lines"_"$j where="$(echo $k)" --overwrite
            echo "lines"_"$j" >> $VARIABLES/feature_types/line_to_geoserver
            i=$(($i+1))
        done                        
        
        
        #From multipolygons extract these elements:
        touch $VARIABLES/feature_types/multipolygon_to_geoserver
        n=$(cat $VARIABLES/feature_types/multipolygon | wc -l)
        i=1
        until [ $i -gt $n ]; do
            j=$(echo $(cat $VARIABLES/feature_types/multipolygon | head -n$i | tail -n1 | cut -d":" -f1))
            k=$(echo $(cat $VARIABLES/feature_types/multipolygon | head -n$i | tail -n1 | cut -d":" -f2))
            grass ~/cityapp/grass/global/PERMANENT --exec v.extract input=multipolygons output=polygon"_"$j where="$(echo $k)" --overwrite
            echo "polygon"_"$j" >> $VARIABLES/feature_types/multipolygon_to_geoserver
            i=$(($i+1))
        done
        
        # Export these maps to the geoserver data_dir
        n=$(cat $VARIABLES/feature_types/multipolygon_to_geoserver | wc -l)
        i=1
        until [ $i -gt $n ]; do
            j=$(echo $(cat $VARIABLES/feature_types/multipolygon_to_geoserver | head -n$i | tail -n1 ))
            grass ~/cityapp/grass/global/PERMANENT --exec v.out.ogr format=GPKG input=$j output=$GEOSERVER/$j".gpkg" --overwrite
            i=$(($i+1))
        done
        
        EXIT_CODE=1;;
    
    "1")
        # Refine or redefine the area selection
        
        cp -r $GEOSERVER/saved/points.gpkg $GEOSERVER/
        cp -r $GEOSERVER/saved/lines.gpkg $GEOSERVER/
        cp -r $GEOSERVER/saved/polygons.gpkg $GEOSERVER/
        
        EXIT_CODE=1;;
        
    "2")
        exit;;
esac

case $EXIT_CODE in
    "1")
        cp $MODULES/location_selector/location_selector_base.html $MODULES/location_selector/location_selector.html

        # Inserting the center coordinates of the new area in the location_selector.html
            EAST=$(grass ~/cityapp/grass/global/PERMANENT --exec g.region -cg vector=lines_highway | head -n1 | cut -d"=" -f2)
            NORTH=$(grass ~/cityapp/grass/global/PERMANENT --exec g.region -cg vector=lines_highway | head -n2 | tail -n1 | cut -d"=" -f2)                

            echo $EAST
            echo $NORTH
        
        # Replace the line in location_selector.html containing the coordinates
            sed -e '132d' $MODULES/location_selector/location_selector.html > $MODULES/location_selector/location_selector_temp.html
            
            sed -i "132i\
            var map = new L.Map('map', {center: new L.LatLng($NORTH, $EAST), zoom: 13 }),drawnItems = L.featureGroup().addTo(map);\
            " $MODULES/location_selector/location_selector_temp.html
            
            mv $MODULES/location_selector/location_selector_temp.html $MODULES/location_selector/location_selector.html

        # Now the same for the module_1_query.html
            sed -e '150d' $MODULES/module_1/module_1_query.html > $MODULES/module_1/module_1_query_temp.html
            
            sed -i "150i\
            var map = new L.Map('map', {center: new L.LatLng($NORTH, $EAST), zoom: 13 }),drawnItems = L.featureGroup().addTo(map);\
            " $MODULES/module_1/module_1_query_temp.html
        
            mv $MODULES/module_1/module_1_query_temp.html $MODULES/module_1/module_1_query.html
        
        # Now the same for the module_1_result.html
            sed -e '150d' $MODULES/module_1/module_1_result.html > $MODULES/module_1/module_1_result_temp.html
            
            sed -i "150i\
            var map = new L.Map('map', {center: new L.LatLng($NORTH, $EAST), zoom: 13 }),drawnItems = L.featureGroup().addTo(map);\
            " $MODULES/module_1/module_1_result_temp.html
        
            mv $MODULES/module_1/module_1_result_temp.html $MODULES/module_1/module_1_result.html
            
        # Start location_selector.html
        kdialog --msgbox "Now the Location Selector is starting. Zoom to area of your interest, then use drawing tool to define your location. Next, save your selection. After saving your selection, close the window." 
        
        falkon $MODULES/location_selector/location_selector.html
        
        ###################################
        ## Basic operations in the GRASS ##--------------
        ###################################

        grass ~/cityapp/grass/global/PERMANENT --exec v.in.ogr -o input=~/cityapp/data_from_browser/"$(ls -ct1 ~/cityapp/data_from_browser | head -n1)" output=selection --overwrite;
        
        rm -fR ~/cityapp/grass/global/project/
        mkdir ~/cityapp/grass/global/project
        cp -r ~/cityapp/grass/skel/* ~/cityapp/grass/global/project

        # Clip the basemap (downloaded from osm and imported into GRASS) with the area_of_interest, defined by the user
        # Results will stored in the "project" mapset
        
        for i in $(grass ~/cityapp/grass/global/project --exec g.list type=vector mapset=PERMANENT); do
            grass ~/cityapp/grass/global/project --exec v.clip input=$i"@PERMANENT" clip=selection@PERMANENT output=$i
        done
        
        cp $GEOSERVER/points.gpkg $GEOSERVER/saved/
        cp $GEOSERVER/lines.gpkg $GEOSERVER/saved/
        cp $GEOSERVER/polygons.gpkg $GEOSERVER/saved/

        grass ~/cityapp/grass/global/project --exec v.out.ogr format=GPKG input=points output=$GEOSERVER/points".gpkg" --overwrite
        grass ~/cityapp/grass/global/project --exec v.out.ogr format=GPKG input=lines output=$GEOSERVER/lines".gpkg" --overwrite
        grass ~/cityapp/grass/global/project --exec v.out.ogr format=GPKG input=polygons output=$GEOSERVER/polygons".gpkg" --overwrite       
        
        grass ~/cityapp/grass/global/project --exec g.remove -f type=vector name=lines,points,polygons;;
esac
        
exit
