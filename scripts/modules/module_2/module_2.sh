#! /bin/bash
# version 0.1
# CityApp module
# Query module
# The network is the road network, with user-defined average speed.
# Defining "from_points" is mandatory, "via_points" and "to_points" are optional.
# If no "to_points" are selected, the default "to_points" will used: points along the roads, calculated by the application. 
# 2020. január 24.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
GRASS=~/cityapp/grass/global/module_1
PERMANENT=~/cityapp/grass/global/PERMANENT
MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/module_1
BUTTONS=$(cat ~/cityapp/scripts/shared/variables/lang)/location_selector_buttons
# An example message:
# kdialog --yes-label "$(cat $BUTTONS | head -n1 | tail -n1)" --no-label "$(cat $BUTTONS | head -n3 | tail -n1)" --yesno "$(cat $MESSAGES | head -n1 | tail -n1)"

