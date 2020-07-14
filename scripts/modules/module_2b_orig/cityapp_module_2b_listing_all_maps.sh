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
MODULE=~/cityapp/scripts/modules/module_2b
MODULE_NAME=cityapp_module_2b_listing
VARIABLES=~/cityapp/scripts/shared/variables
GRASS=~/cityapp/grass/global
MAPSET=PERMANENT

# -- processing -----

    Running_Check start
    rm -f $MODULE/temp_maps
    touch $MODULE/temp_maps
    for i in $(g.list mapset=PERMANENT type=vector | grep -vE 'lines_osm|lines|points_osm|polygons_osm|polygons|relations_osm|relations|selection'); do
        echo $i >> $MODULE/temp_maps
    done
    Running_Check stop
exit 
