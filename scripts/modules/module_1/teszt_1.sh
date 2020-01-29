#! /bin/bash
# version 1.1
# CityApp module
# This module is to calculate the fastest way from "from_points" to "to_points" thru "via_points".
# The network is the road network, with user-defined average speed.
# Defining "from_points" is mandatory, "via_points" and "to_points" are optional.
# If no "to_points" are selected, the default "to_points" will used: points along the roads, calculated by the application. 
# 2020. január 24.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

CITYAPP=$(cat ~/.cityapp/init_dir)
GEOSERVER=$CITYAPP/geoserver_data
MODULES=$CITYAPP/scripts/modules
VARIABLES=$CITYAPP/scripts/shared/variables
BROWSER=$CITYAPP/data_from_browser
GRASS=$CITYAPP/grass/global/module_2
PERMANENT=$CITYAPP/grass/global/PERMANENT
MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/module_2
BUTTONS=$(cat $CITYAPP/scripts/shared/variables/lang)/module_2_buttons

echo $CITYAPP
echo $GEOSERVER
echo $MODULES
echo $VARIABLES
echo $BROWSER
echo $GRASS
echo $PERMANENT
echo $MESSAGES
echo $BUTTONS

exit


if [ -e $VARIABLES/location_new ]
    then
        if [ -e $MODULES/module_1/ack_location_new ]
            then
                echo "INIT=3"
                echo "location_new AND ack_location_new"
            else
                echo "INIT=1"
                touch $MODULES/module_1/ack_location_new
                rm -f $MODULES/module_1/ack_location_mod
                echo "location_new BUT ack_location_new"
        fi
    else
        if [ -e $VARIABLES/location_mod ]
            then
                if [ -e $MODULES/module_1/ack_location_mod ]
                    then
                        echo "INIT=3"
                        echo "location_mod AND ack_location_mod"
                    else
                        echo "INIT=2"
                        echo "location_mod BUT ack_location_mod"
                        touch $MODULES/module_1/ack_location_mod
                        rm -f $MODULES/module_1/ack_location_new
                fi
            else
                # MESSAGE 15
                kdialog --error "$(cat $MESSAGES | head -n15 | tail -n1)"
        fi
fi
