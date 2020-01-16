#! /bin/bash

cd

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
VARIABLES=~/cityapp/scripts/shared/variables
MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/location_selector
# An example message:
# kdialog --yesnocancel "$(cat $MESSAGES | head -n1 | tail -n1)"

# Message 1 #
kdialog --yesnocancel "$(cat $MESSAGES | head -n1 | tail -n1)"

#yes = 0
#no = 1
#cancel = 2

case $? in
    "0")
        # Message 2 #
        NEW_AREA_FILE=$(kdialog --getopenfilename ~/ --title "$(cat $MESSAGES | head -n2 | tail -n1)")

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

        # Copy basemaps into $GEOSERVER/saved
        # From now this directorya will contains the original, unclipped maps.
        # This may useful for further operations.
        cp $GEOSERVER/points.gpkg $GEOSERVER/saved/
        cp $GEOSERVER/lines.gpkg $GEOSERVER/saved/
        cp $GEOSERVER/polygons.gpkg $GEOSERVER/saved/
        
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
        # Message 3 # 
        kdialog --msgbox "$(cat $MESSAGES | head -n3 | tail -n1)"

        falkon $MODULES/location_selector/location_selector.html

        ###################################
        ## Basic operations in the GRASS ##--------------
        ###################################

        grass ~/cityapp/grass/global/PERMANENT --exec v.in.ogr -o input=~/cityapp/data_from_browser/"$(ls -ct1 ~/cityapp/data_from_browser | head -n1)" output=selection --overwrite;;
esac

# Message 4
kdialog --msgbox "$(cat $MESSAGES | head -n4 | tail -n1)"
falkon http://localhost:8080/geoserver/web/

exit
