#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.1
# CityApp maintenance
# Select language for CityApp messages
# 2020. május 19.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/select_lang
GRASS=~/cityapp/grass/global
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/select_lang
MESSAGE_SENT=~/cityapp/data_to_client

#
#-- Process ----------------------------
#
Running_Check start

rm -f $MESSAGE_SENT/*

ls -1 ~/cityapp/scripts/shared/messages > $MODULE/available_languages

Send_Message l 1 select_lang_1 select actions [\"yes\"] $MODULE/available_languages
    Request
        if [ -z $REQUEST_CONTENT ]
            then
                Send_Message m 2 select_lang_2 error actions [\"ok\"]
                Request
                    echo "en" > $VARIABLES/lang
                    Close_Process
                    exit
            else
                echo $REQUEST_CONTENT > $VARIABLES/lang
        fi

Send_Message m 3 select_lang_3 question actions [\"ok\"]
    Request
        Running_Check stop
        Close_Process
exit
