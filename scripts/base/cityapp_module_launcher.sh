#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.3
# CityApp module
# This module is to check launcer.html
# when file "launch" exist, execute its content
#
# Core module, do not modify!
#
# 2020. március 3.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/base
MODULE_NAME=module_launcher
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_launcher
MESSAGE_SENT=~/cityapp/data_to_client
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)

rm -f ~/cityapp/scripts/base/html/map.html
ln -s $MODULES/base_map/base_map.html ~/cityapp/scripts/base/html/map.html

rm -f $BROWSER/*
rm -f $MESSAGE_SENT/*
touch $VARIABLES/launcher_run

#
#-- Process ----------------------------
#


Send_Message m 3 module_launcher.1 question actions [\"Yes\"]

while FRESH_FILE=$(inotifywait -e create --format %f $BROWSER); do
    FRESH_CONT=$(cat $BROWSER/$FRESH_FILE)
    
    case $FRESH_FILE in
        "EXIT")
            Send_Message m 2 system_error.2 error actions [\"yes\"]
                # Request
                ~/cityapp/scripts/base/ca_shutdown.sh
            ;;
        "launch")
            if [ -e $VARIABLES/launch_locked ]
                then
                    Send_Message m 1 sytem_error.1 error actions [\"yes\"]
                    rm -f $BROWSER/launch
                else
                    rm -f $BROWSER/*
                    $MODULES/$FRESH_CONT/"cityapp_"$FRESH_CONT".sh" &
            fi
            ;;
    esac
done

Send_Message m 2 system_error.2 error actions [\"yes\"]
    Request
~/cityapp/scripts/base/ca_shutdown.sh
exit
