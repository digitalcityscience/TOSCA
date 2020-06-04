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

rm -f $BROWSER/*
rm -f $MESSAGE_SENT/*
touch $VARIABLES/launcher_run
rm -f $VARIABLES/last_launched

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
                # ~/cityapp/scripts/base/ca_shutdown.sh
            ;;
        "launch")
            IS_LAUNCHED=$(ps a | grep $LAST_LAUNCHED | grep -v grep)
            echo $IS_LAUNCHED
            if [ "$IS_LAUNCHED">0 ]
                then
                    Send_Message m 1 sytem_error.1 error actions [\"yes\"]
                    rm -f $BROWSER/launch
                else
                    rm -f $BROWSER/*
                    $MODULES/$NEW_CONTENT/"cityapp_"$NEW_CONTENT".sh" &
                    LAST_LAUNCHED="cityapp_"$NEW_CONTENT".sh"
                    echo $LAST_LAUNCHED > $VARIABLES/last_launched
                    pgrep -f $LAST_LAUNCHED >> $VARIABLES/last_launched
            fi
            ;;
        "RESTART")
            rm -f $BROWSER/*
            rm -f $MESSAGE_SENT/*
            touch $VARIABLES/launcher_run
            rm -f $VARIABLES/last_launched
            ;;
    esac
done

Send_Message m 2 system_error.2 error actions [\"yes\"]
    Request
        rm -f $VARIABLES/last_launched
# ~/cityapp/scripts/base/ca_shutdown.sh
exit
