#! /bin/bash
# version 1.0
# CityApp maintenance
# Resolution setting
# 2020. január 24.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

MESSAGES=$(cat ~/cityapp/scripts/shared/variables/lang)/resolution_setting
RES=$(cat ~/cityapp/scripts/shared/variables/resolution | head -n3 | tail -n1)
RES_VAL=$RES
# Defining resolution for the entire CityApp
# Projection is epsg:4326-ot. Therefore, even the user gives the resolutiion in mteres, we have to pass its value to GRASS in decimal degrees.
# Therefore, input aluie first goes to "bc". 111322 meters = 1°

# Messages 1
RESOLUTION=$(kdialog --title "Resolution" --textinputbox "$(cat $MESSAGES | head -n1 | tail -n1)" "$RES_VAL")
RESOLUTION=$(echo $RESOLUTION | cut -d"," -f1)
RESOLUTION=$(echo $RESOLUTION | cut -d"." -f1)

if [ $RESOLUTION -le 0 ]
    then
        until [ $RESOLUTION -gt 0 ]; do 
            # Message 2
            RESOLUTION=$(kdialog --title "Resolution" --textinputbox  "$(cat $MESSAGES | head -n2 | tail -n1)")
            
            RESOLUTION=$(echo $RESOLUTION | cut -d"," -f1)
            RESOLUTION=$(echo $RESOLUTION | cut -d"." -f1)
        done
    else
        echo "First data: Resolution in meters, given by the user." > ~/cityapp/scripts/shared/variables/resolution
        echo "Second data: resolution in decimal degrees, derivated from first data." >> ~/cityapp/scripts/shared/variables/resolution
        echo "$RESOLUTION" >> ~/cityapp/scripts/shared/variables/resolution
        echo "$RESOLUTION/111322" | bc -l | sed -e 's/^-\./-0./' -e 's/^\./0./' >> ~/cityapp/scripts/shared/variables/resolution
fi
