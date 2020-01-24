#! /bin/bash
# version 1.0
# CityApp module
# Import OSM maps into PERMANENT mapset. Points, lines, polygons, relations are only imported. Other maps can be extracted from these in separate modules.
# To import other maps, use Add Layer module.
# 2020. január 24.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
VARIABLES=~/cityapp/scripts/shared/variables
GRASS=~/cityapp/grass/global
MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/location_selector
BUTTONS=$(cat ~/cityapp/scripts/shared/variables/lang)/location_selector_buttons
# An example message:
# kdialog --yes-label "$(cat $BUTTONS | head -n1 | tail -n1)" --no-label "$(cat $BUTTONS | head -n3 | tail -n1)" --yesno "$(cat $MESSAGES | head -n1 | tail -n1)"
#yes = 0
#no = 1
#cancel = 2

function coordinates 
{
if [ $(grass $GRASS/PERMANENT --exec g.list type=vector | grep selection) ]
    then
        EAST=$(grass $GRASS/PERMANENT --exec g.region -cg vector=selection | head -n1 | cut -d"=" -f2)
        NORTH=$(grass $GRASS/PERMANENT --exec g.region -cg vector=selection | head -n2 | tail -n1 | cut -d"=" -f2)
    else
        EAST=$(grass $GRASS/PERMANENT --exec g.region -cg vector=polygons_osm | head -n1 | cut -d"=" -f2)
        NORTH=$(grass $GRASS/PERMANENT --exec g.region -cg vector=polygons_osm | head -n2 | tail -n1 | cut -d"=" -f2)
fi
# Replace the line in location_selector.html containing the coordinates
sed -e '129d' $MODULES/location_selector/location_selector.html > $MODULES/location_selector/location_selector_temp.html
sed -i "129i\
var map = new L.Map('map', {center: new L.LatLng($NORTH, $EAST), zoom: 9 }),drawnItems = L.featureGroup().addTo(map);\
" $MODULES/location_selector/location_selector_temp.html
mv $MODULES/location_selector/location_selector_temp.html $MODULES/location_selector/location_selector.html
}

if [ ! -d "$GRASS/PERMANENT/" ]
    then
        # PERMANENT not found
        # Message 1 #
        kdialog --yes-label "$(cat $BUTTONS | head -n1 | tail -n1)" --no-label "$(cat $BUTTONS | head -n3 | tail -n1)" --yesno "$(cat $MESSAGES | head -n1 | tail -n1)"
        if [ $? -eq 0 ]
            then
                INIT=0
                # Message 2 #
                NEW_AREA_FILE=$(kdialog --getopenfilename ~/ --title "$(cat $MESSAGES | head -n2 | tail -n1)")
            else
                exit
        fi
    else
        # PERMANENT found
        # Message 2 #
        kdialog --yes-label "$(cat $BUTTONS | head -n1 | tail -n1)" --no-label "$(cat $BUTTONS | head -n2 | tail -n1)" --cancel-label "$(cat $BUTTONS | head -n3 | tail -n1)" --yesnocancel "$(cat $MESSAGES | head -n2 | tail -n1)"
        case $? in
            0)
                INIT=0
                # Message 3 #
                NEW_AREA_FILE=$(kdialog --getopenfilename ~/ --title "$(cat $MESSAGES | head -n3 | tail -n1)");;
            1)
                INIT=1;;
            2)
                exit;;
        esac
fi

case $INIT in
    0)
        rm -f $GEOSERVER/*
        rm -fR $GRASS/PERMANENT/
        mkdir $GRASS/PERMANENT
        cp -r ~/cityapp/grass/skel_permanent/* $GRASS/PERMANENT

        grass $GRASS/PERMANENT --exec v.in.ogr -o -e input=$NEW_AREA_FILE layer=points output=points_osm --overwrite
        grass $GRASS/PERMANENT --exec v.in.ogr -o -e input=$NEW_AREA_FILE layer=lines output=lines_osm --overwrite
        grass $GRASS/PERMANENT --exec v.in.ogr -o -e input=$NEW_AREA_FILE layer=multipolygons output=polygons_osm --overwrite
        grass $GRASS/PERMANENT --exec v.in.ogr -o -e input=$NEW_AREA_FILE layer=other_relations output=relations_osm --overwrite
        grass $GRASS/PERMANENT --exec v.out.ogr format=GPKG input=points_osm output=$GEOSERVER/points".gpkg" --overwrite
        grass $GRASS/PERMANENT --exec v.out.ogr format=GPKG input=lines_osm output=$GEOSERVER/lines".gpkg" --overwrite
        grass $GRASS/PERMANENT --exec v.out.ogr format=GPKG input=polygons_osm output=$GEOSERVER/polygons".gpkg" --overwrite

        # Copy basemaps into $GEOSERVER/saved
        # From now this directory will contains the original, unclipped maps.
        # This may useful for further operations.
        cp $GEOSERVER/points.gpkg $GEOSERVER/saved/
        cp $GEOSERVER/lines.gpkg $GEOSERVER/saved/
        cp $GEOSERVER/polygons.gpkg $GEOSERVER/saved/
        rm -f $VARIABLES/location_mod
        touch $VARIABLES/location_new;;
    1)
        # Refine or redefine the area selection
        rm -f $VARIABLES/location_new
        touch $VARIABLES/location_mod;;
    2)
        exit;;
esac

        if [ ! -e $GRASS/PERMANENT/vector/lines_osm ]
            then
                # Message 5
                kdialog --msgbox "$(cat $MESSAGES | head -n5 | tail -n1)"
                exit
        fi

# Inserting the center coordinates of the new area in the location_selector.html
coordinates

# Start location_selector.html
# Message 6 # 
kdialog --msgbox "$(cat $MESSAGES | head -n6 | tail -n1)"
falkon $MODULES/location_selector/location_selector.html &
 
inotifywait -e close_write ~/cityapp/data_from_browser/

# Message 7 # 
kdialog --yesno "$(cat $MESSAGES | head -n7 | tail -n1)"
if [ $? -eq 0 ]
    then
        ~/cityapp/scripts/maintenance/resolution_setting.sh
fi

# Basic operations in the GRASS
# Selection import to GRASS and export to Geoserver as gpkg.
grass $GRASS/PERMANENT --exec v.in.ogr -o -o input=~/cityapp/data_from_browser/"$(ls -ct1 ~/cityapp/data_from_browser | head -n1)" output=selection --overwrite
grass $GRASS/PERMANENT --exec v.out.ogr format=GPKG input=selection output=$GEOSERVER/selection".gpkg" --overwrite --quiet
rm -f ~/cityapp/data_from_browser/data.geojson

grass $GRASS/PERMANENT --exec v.clip input=polygons_osm clip=selection output=polygons --overwrite
grass $GRASS/PERMANENT --exec v.clip input=lines_osm clip=selection output=lines --overwrite
grass $GRASS/PERMANENT --exec v.clip input=relations_osm clip=selection output=relations --overwrite

# Finally, have to set Geoserver to display raster outputs (such as time_map) properly.
# For this end, first have to prepare a "fake time_map". This is a simple geotiff, a raster version of "selection" vector map.
# This will  exported to geoserver data dir as "time_map.tif".
# Now the Geoserver have to be restarted manually and from that point, rastermaps of this locations will accepted automatically.
# This process only have to repeated, when new location is created.
# First check if a new location was created, or only a refining of the current selection:

if [  $INIT -eq 0 ]
    then
        grass $GRASS/PERMANENT --exec g.region vector=selection res=$(cat ~/cityapp/scripts/shared/variables/resolution | tail -n1) 
        grass $GRASS/PERMANENT --exec v.to.rast input=selection output=time_map use=val value=1 --overwrite --quiet
        grass $GRASS/PERMANENT --exec r.out.gdal input=time_map output=$GEOSERVER/time_map.tif format=GTiff type=Float64 --overwrite --quiet

        kdialog --msgbox "After adding the new location, you have to (re)start Geoserver manually." 
fi

# Updating center coordinater to the area of selection
coordinates
kdialog --msgbox "Process finished. No you can exit CityApp Location selector" 
exit
