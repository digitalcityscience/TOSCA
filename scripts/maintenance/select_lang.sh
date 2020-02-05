#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.0
# CityApp maintenance
# Select language for CityApp messages
# 2020. február 5.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
MESSAGE_SENT=~/cityapp/data_to_client

#
#-- Process ----------------------------
#

rm -f $MESSAGE_SENT/*

echo "Select language. Available languages are:" > $MESSAGE_SENT/message.select_lang.1
echo >> $MESSAGE_SENT/message.select_lang.1
ls -1 ~/cityapp/scripts/shared/messages >> $MESSAGE_SENT/message.select_lang.1

Request
    if [ -z $REQUEST_CONTENT ]
        then
            echo "Network error, language is not set. Please restart Lagnuage Settings module to set a languages." > $MESSAGE_SENT/message.select_lang.1
            exit
        else
            echo $REQUEST_CONTENT > $VARIABLES/lang
    fi
exit
