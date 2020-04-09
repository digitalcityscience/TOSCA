#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.31
# CityApp maintenance
# Resolution setting
# 2020. április 9.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/resolution_setting
MODULE_NAME=cityapp_resolution_setting
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/resolution_setting
MESSAGE_SENT=~/cityapp/data_to_client

touch $VARIABLES/.launch_locked

#
#-- Process ----------------------------
#

RES=$(cat $VARIABLES/resolution | head -n3 | tail -n1)
RES_VAL=$RES
# Defining resolution for the entire CityApp
# Projection is epsg:4326-ot. Therefore, even the user gives the resolutiion in mteres, we have to pass its value to GRASS in decimal degrees.
# Therefore, input always first goes to "bc". 111322 meters = 1°

# Messages 1 Type the resolution in meters, you want to use. For further details see manual.
Send_Message m 1 resolution_setting.1 input actions [\"OK\"]
    Request
    RESOLUTION=$REQUEST_CONTENT
    RESOLUTION=$(echo $RESOLUTION | cut -d"," -f1)
    RESOLUTION=$(echo $RESOLUTION | cut -d"." -f1)

    if [ $RESOLUTION -le 0 ]
        then
            until [ $RESOLUTION -gt 0 ]; do 
                # Message 2 Resolution has to be an integer number, greater than 0.  Please, define the resolution for calculations in meters.
                Send_Message m 2 resolution_setting.2 input actions [\"OK\"]
                    Request
                    RESOLUTION=$REQUEST_CONTENT
                    RESOLUTION=$(echo $RESOLUTION | cut -d"," -f1)
                    RESOLUTION=$(echo $RESOLUTION | cut -d"." -f1)
            done
        else
            echo "First data: Resolution in meters, given by the user." > $VARIABLES/resolution
            echo "Second data: resolution in decimal degrees, derivated from first data." >> $VARIABLES/resolution
            echo "$RESOLUTION" >> $VARIABLES/resolution
            echo "$RESOLUTION/111322" | bc -l | sed -e 's/^-\./-0./' -e 's/^\./0./' >> $VARIABLES/resolution
            

            CONTROL_LINE_3=$(cat $VARIABLES/resolution | head -n3 | tail -n1 | grep [0-9] | grep -v [a-z,A-Z] | wc -c)
            CONTROL_LINE_4=$(cat $VARIABLES/resolution | head -n4 | tail -n1 | grep [0-9] | grep -v [a-z,A-Z] |wc -c)
                                
            if [[ $CONTROL_LINE_3 -gt 0 ]] && [[ $CONTROL_LINE_4 -gt 0 ]]
                then
                    if [ "$CONTROL_LINE_3" == "$CONTROL_LINE_4" ]
                        then
                            touch $MESSAGE_SENT/message.resolution_setting.3
                            echo "{ "\""success"\"": false }" > $MESSAGE_SENT/message.resolution_setting.3
                        else
                            touch $MESSAGE_SENT/message.resolution_setting.3
                            echo "{ "\""success"\"": true }" > $MESSAGE_SENT/message.resolution_setting.3
                    fi
                else
                    touch $MESSAGE_SENT/message.resolution_setting.3
                    echo "{ "\""success"\"": false }" > $MESSAGE_SENT/message.resolution_setting.3
            fi
    fi
sleep 1s
Close_Process
exit
