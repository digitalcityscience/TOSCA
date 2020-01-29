#! /bin/bash
# version 0.1
# CityApp module
# This module is to query any existing map by a user-defined area or user-selected area map.
# 2020. január 26.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
GRASS=~/cityapp/grass/global/module_2
PERMANENT=~/cityapp/grass/global/PERMANENT
MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/module_2
BUTTONS=$(cat ~/cityapp/scripts/shared/variables/lang)/module_2_buttons

    for i in $(cat $MODULES/module_2/query_this_slum_houses);do
        echo $i
    done

exit
