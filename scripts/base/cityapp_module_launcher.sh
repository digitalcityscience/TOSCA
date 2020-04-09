#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.32
# CityApp module
# This module is to check launcer.html
# when file "launch" exist, execute its content
#
# Core module, do not modify!
#
# 2020. március 26.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/base
MODULE_NAME=module_launcher
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_launcher
MESSAGE_SENT=~/cityapp/data_to_client

rm -f ~/cityapp/scripts/base/html/map.html
ln -s $MODULES/base_map/base_map.html ~/cityapp/scripts/base/html/map.html

rm -f $BROWSER/*
rm -f $MESSAGE_SENT/*
touch $VARIABLES/launcher_run

#
#-- Process ----------------------------
#


#Send_Message m 3 module_launcher.1 question actions [\"Yes\"]

while NEW_FILE=$(inotifywait -e create --format %f $BROWSER); do
    NEW_CONTENT=$(cat $BROWSER/$NEW_FILE)
    
    case $NEW_FILE in
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
                    $MODULES/$NEW_CONTENT/"cityapp_"$NEW_CONTENT".sh" &
                    ps a | grep "inotifywait" | grep -v "grep" | cut -d" " -f1 > $VARIABLES/launcher_watcher
            fi
            ;;
    esac
done

Send_Message m 2 system_error.2 error actions [\"yes\"]
    Request
~/cityapp/scripts/base/ca_shutdown.sh
exit
