#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.0
# CityApp module
# This module is to list available maps for module_2
#
# 2020. április 14.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/module_2
MODULE_NAME=cityapp_module_2_listing
VARIABLES=~/cityapp/scripts/shared/variables
GRASS=~/cityapp/grass/global
MAPSET=PERMANENT

# -- processing -----

rm -f $MODULE/temp_maps
touch $MODULE/temp_maps
for i in $(g.list mapset=PERMANENT type=vector | grep -vE 'lines_osm|lines|points_osm|polygons_osm|polygons|relations_osm|relations|selection'); do
    if [[ $(db.describe -c table=$i | grep -E 'DOUBLE\ PRECISION|INTEGER' | grep -vE 'CAT|cat') ]]
        then
            echo $i >> $MODULE/temp_maps
    fi
done

exit 
