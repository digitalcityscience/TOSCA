#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.2
# CityApp module
# This module is to check launcer.html
# when file "launch" exist, execute its content
#
# Core module, do not modify!
#
# 2020. február 13.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/base
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_launcher
MESSAGE_SENT=~/cityapp/data_to_client

#
#-- Process ----------------------------
#

while inotifywait -e close_write $BROWSER/; do
    Select_Fresh
    FRESH_FILE=$OUTPUT
    FRESH=$(cat $OUTPUT)
    
    if [ $(echo $FRESH_FILE | grep launch) ]
        then
            if [ -e $BROWSER/.launch_locked ]
                then
                    # Message 1 CityApp is already running in the selected userbox. You may manually override this warning removing the .launch.locked file. For this purpose select CityApp Restart tool.
                    Send_Message m 1 sytem_error.1 error actions [\"yes\"]
                    Request
                    rm -f $FRESH_FILE
                else
                    $MODULES/$FRESH/$FRESH".sh" &
                    touch $BROWSER/.launch_locked
            fi
            
    fi
    
    if [ $(echo $FRESH_FILE | grep EXIT) ]
        then
            # Message 2 CityApp is now exiting. To restart CityApp, use Restart tool.
            Send_Message m 2 system_error.2 error actions [\"yes\"]
            Request
            rm -f $MESSAGE_SENT/*
            rm -f $BROWSER/.*
            rm -f $BROWSER/*
            exit
    fi
done

Send_Message m 2 system_error.2 error actions [\"yes\"]
Request
rm -f $MESSAGE_SENT/*
rm -f $BROWSER/.*
rm -f $BROWSER/*

Close_Process
exit
