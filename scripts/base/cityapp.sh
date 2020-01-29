#! /bin/bash
# version 1.2
# CityApp module
# This module is to calculate the fastest way from "from_points" to "to_points" thru "via_points".
# The network is the road network, with user-defined average speed.
# Defining "from_points" is mandatory, "via_points" and "to_points" are optional.
# If no "to_points" are selected, the default "to_points" will used: points along the roads, calculated by the application. 
# 2020. január 24.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

cd ~/cityapp

xterm -e /usr/share/geoserver/bin/shutdown.sh
xterm -e /usr/share/geoserver/bin/startup.sh &
xterm -e ~/cityapp/scripts/base/module_launcher.sh &
falkon ~/cityapp/scripts/base/html_pages/launch.html
exit
