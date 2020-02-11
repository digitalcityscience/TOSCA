#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.2
# CityApp module
# This module is to query any existing map by a user-defined area
# 2020. február 5.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/module_2
GRASS=~/cityapp/grass/global
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_2
MESSAGE_SENT=~/cityapp/data_to_client
MAPSET=module_2

#felirat 4
#adat 6

    # $1 -- type "m": message only, a single line; "s": simple list, long format "l": complex list with a user dialogue message in the first line;
    # $2 -- CityApp message (order number of a single line in the message file of current module);
    # $3 -- Output JSON file (after converting a simple list into JSON);
    # $4 -- modalType. (actions, list, select)
    # $5 -- action type. Simple "action" for yesnocancel like questions , and "select" for list and other selections
    # $6 -- possible outcomes. format is: ["yes","no","cancel"]
    # $7 -- previously it was $4 -- list file: this is a list have to transform ito JSON format for the Browser;  }

# What is the map you want to query? Available maps are:

Send_Message l 2 test_1.1 actions action [\"yes\",\"no\",\"cancel\"] $VARIABLES/roads_speed

exit
