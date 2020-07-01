#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 0.1
# CityApp module
# An IAUAI-project module
# 2020. május 13.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/module_101
MODULE_NAME=cityapp_module_101
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_101
MESSAGE_SENT=~/cityapp/data_to_client
GEOSERVER=~/cityapp/geoserver_data
GRASS=~/cityapp/grass/global
MAPSET=module_101

RESOLUTION=$(cat $VARIABLES/resolution | head -n4 | tail -n1)
rm -f $MESSAGE_SENT/*

# 
# Checking requested components
#

# First overwrite the region of module_101 mapset. If there is no such mapset, create it
    if [ -d $GRASS/$MAPSET ]
        then
            # It is simpler and faster to always copy the PERMANENT WIND than to check if is it chaged or not
                cp $GRASS/PERMANENT/WIND $GRASS/$MAPSET/WIND
        else
            # Scorched earth. Brand new mapset, has to build everithing.
                mkdir $GRASS/$MAPSET
                cp -r ~/cityapp/grass/skel/* $GRASS/$MAPSET
                cp $GRASS/PERMANENT/WIND $GRASS/$MAPSET/WIND
    fi

if [ ! -d $GRASS/PERMANENT ]
    then
    # check if PERMANENT mapeset exist
        # Message 1 No valid location found. Run Location selector to create a valid location
        Send_Message m 1 module_101.1 error actions [\"Ok\"]
            Request
                Close_Process
                exit
fi

# check if terrain model (dem) is already added to  PERMANENT mapset or not.
# Terrain modell has to be added to the mapset (using add_map module), therefore its nomal location is in the PERMANENT.
# Now, for testing only, the search path is: $GRASS/$MAPSET. In the final version this will set to: $GRASS/PERMANENT

if [[ ! -z $(grass -f $GRASS/$MAPSET --exec g.list type=raster | grep _dem_) ]]
    then
        DEM=$(grass -f $GRASS/$MAPSET --exec g.list type=raster | grep _dem_)
    else
        # Message 2 No terrain model map found. First add a terrain model map to the mapset. For further info, please, consult the user's manual.
        Send_Message m 2 module_101.2 error actions [\"Ok\"]
            Request
                Close_Process
                exit
fi

                # Creating map of water bodies, by extracting them from lines_osm and multipolygons_osm
                Process_Check start map_calculations
            
                grass -f $GRASS/$MAPSET --exec v.extract input=polygons_osm@PERMANENT where="natural='water'"  
                water_polygon --overwrite
                
                grass -f $GRASS/$MAPSET --exec v.extract input=polygons_osm@PERMANENT where="natural='bay' OR natural='beach' OR natural='coastline'" output=water_coasts_polygon --overwrite
                
                grass -f $GRASS/$MAPSET --exec v.extract input=lines_osm@PERMANENT where="waterway='river'" output=river_lines --overwrite
                
                grass -f $GRASS/$MAPSET --exec v.extract input=lines_osm@PERMANENT where="waterway='riverbank'" output=riverbank_lines --overwrite
                
                grass -f $GRASS/$MAPSET --exec v.extract input=lines_osm@PERMANENT where="waterway='stream'" output=stream_lines --overwrite
                
                grass -f $GRASS/$MAPSET --exec v.extract input=lines_osm@PERMANENT where="waterway='tidal_channel'" output=tidal_channel_lines --overwrite
                
                grass -f $GRASS/$MAPSET --exec v.extract input=lines_osm@PERMANENT where="waterway='canal'" output=canal_lines --overwrite
                
                grass -f $GRASS/$MAPSET --exec v.extract input=lines_osm@PERMANENT where="waterway='drain'" output=drain_lines --overwrite
                grass -f $GRASS/$MAPSET --exec v.extract input=lines_osm@PERMANENT where="waterway='ditch'" output=ditch_lines --overwrite
                grass -f $GRASS/$MAPSET --exec v.extract input=lines_osm@PERMANENT where="waterway='waterfall'" output=waterfall_lines --overwrite
                
                Process_Check stop map_calculations
                
# --------------------------

# Chapter 1
# Rasterizing flowlines, calculating
    Process_Check start map_calculations

    grass -f $GRASS/$MAPSET --exec v.to.rast input=river_lines output=river_lines use=val value=1
    r.mapcalc expression="'river_dem'='river_lines'*'bbswr_dem_'" --overwrite 

    Process_Check stop map_calculations


Close_Process
exit


r.watershed elevation=dem_hu_ne@PERMANENT threshold=1000 accumulation=accumulation tci=topoindex spi=waterpower basin=basins stream=streams --overwrite 

g.region raster=accumulation

d.mon start=wx1
sleep 1s
d.mon select=wx1
d.rast map=accumulation

d.mon start=wx2
sleep 1s
d.rast map=topoindex

TOPO_MAX=$(r.univar -g map=topoindex | grep max= | cut -d"=" -f2 | cut -d"." -f1)
TOPO_STDEV=$(r.univar -g map=topoindex | grep stddev= | cut -d"=" -f2)
TOPO_VALUE=$(($TOPO_MAX-1))
echo $TOPO_VALUE

#
# Already adde osm map is used (added by cityapp_add_map.sh)
#

#
# Chapter 1
# Selecting water bodies from osm base map
#

# Water bodies may stored in "lines" layer of OSM map, imported as "lines" map to GRASS. Inth is case: "waterway>0"
# If water bodies are imported as polygons to "multipolygons" map, then "natural='water'".




#
# Chapter 2
# Calculating surface features
#
