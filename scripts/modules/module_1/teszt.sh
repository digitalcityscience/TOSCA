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

# Message 1 
kdialog --yesnocancel "$(cat $MESSAGES | head -n1 | tail -n1)"

    function add_from_points 
        {
        falkon $MODULES/module_1/module_1_query.html
        mv $BROWSER/"$(ls -ct1 $BROWSER | head -n1 | grep module_01)" $BROWSER/module_1/from.geojson
        echo "var from_points = " > $BROWSER/module_1/from_points.js
        cat $BROWSER/module_1/from.geojson >> $BROWSER/module_1/from_points.js
        }
echo "akármi"
add_from_points
exit
