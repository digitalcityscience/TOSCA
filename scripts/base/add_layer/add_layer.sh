#! /bin/bash
# version 1.0
# CityApp module
# Adding new layer
# 2020. január 24.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
VARIABLES=~/cityapp/scripts/shared/variables
GRASS=~/cityapp/grass/global/PERMANENT
MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/add_layer
BUTTONS=$(cat ~/cityapp/scripts/shared/variables/lang)/location_selector_buttons

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

# First chech if "selection" map exist in PERMAMENT mapset.
# If not, it means, that there is no basemap (because basemap is the imported map cut by selection map)
# Therefore, have to send a message to user, ask him to create first a valid location and selection.
if [ $(grass -f $GRASS --exec g.list type=vector | grep selection) ]
    then
        add_layer
    else
        # Message 4
        kdialog --error "$(cat $MESSAGES | head -n4 | tail -n1)"
fi

# Repeat process. You may add new layers until you select "no".
until [ $DONE -eq 1 ]; do
    add_layer
done
exit
