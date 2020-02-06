#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.2
# CityApp module
# Adding new layers to a selected mapset
# 2020. február 3.
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
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/add_layer
MESSAGE_SENT=~/cityapp/data_to_client
MAPSET=module_2

rm -f $MESSAGE_SENT/*

# First chech if there is a valid PERMAMENT mapset or not.
# If not, have to send a message to user, ask him to create first a valid location.

if [ $(grass -f $GRASS --exec g.list type=vector | grep selection) ]
    then
        add_layer
    else
        # Message 4
        kdialog --error "$(cat $MESSAGES | head -n4 | tail -n1)"
fi

# Deafult mapset is PERMANENT, but of course the user have to asked if want to use other mapset or not.

# 1 To which mapset do you want to add the map
# 2 What is the map name after importing (if exist, overwrite?)
# 3 Select a map (file) to add


function add_layer
    {
    # Message 1
    IN_FILE=$(kdialog --getopenfilename ~/ --title "$(cat $MESSAGES | head -n1 | tail -n1)")

    # Message 2
    OUT_MAP=$(kdialog --inputbox "$(cat $MESSAGES | head -n2 | tail -n1)")

    "Check layers: if more then 1 there is in the file, ask user"
    if [ $(grass -f $GRASS --exec v.in.ogr -l input=$IN_FILE | wc -l) -gt 1 ]
        then
            # List (the name of layers) have to be saved in a separate file, because
            #it later allows to read the list by any kind of scripts, js as well. 
            grass -f $GRASS --exec v.in.ogr -l input=$IN_FILE > $VARIABLES/list
            LIST=$(cat $VARIABLES/list)
            
            # Message 3
            LAYER=$(kdialog --inputbox "$(cat $MESSAGES | head -n3 | tail -n1)
            $(
            echo
            n=1
            for i in $(echo $LIST);do
                echo $n" "$i
                n=$((n+1))
            done)" "Layer number")
            
            OUT_LAYER=$(cat $VARIABLES/list | head -n$LAYER | tail -n1)
            echo "out layer:"
            
            grass -f $GRASS --exec v.in.ogr input=$IN_FILE layer=$OUT_LAYER output=$OUT_MAP --overwrite
        else
            grass -f $GRASS --exec v.in.ogr input=$IN_FILE output=$OUT_MAP --overwrite
    fi
    # Message 5
    kdialog --yesno "$(cat $MESSAGES | head -n5 | tail -n1)"
    DONE=$?
}


# Repeat process. You may add new layers until you select "no".
until [ $DONE -eq 1 ]; do
    add_layer
done
exit
