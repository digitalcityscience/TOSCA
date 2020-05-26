#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.33
# CityApp module
# This module is to shutdown cityapp system
#
# Core module, do not modify!
#
# 2020. május 12.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/base
MODULE_NAME=ca_shutdown
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/ca_restart
MESSAGE_SENT=~/cityapp/data_to_client

#
#-- Process -------------------
#

Send_Message m 1 ca_restart.1 question actions [\"Yes\",\"No\"]
    Request
        ANSWER=$REQUEST_CONTENT
        if [ "$ANSWER"="yes" ]
            then        
                Send_Message m 1 ca_restart.2 question actions [\"Yes\"]
                    Request
                        # close geoserver
                            /usr/share/geoserver/bin/shutdown.sh

                        # clean directories
                            rm -f ~/cityapp/scripts/shared/temp/*
                            rm -f $MESSAGE_SENT/*
                            rm -f $VARIABLES/launcher_run
                            rm -f $VARIABLES/launch_locked
                            rm -f $BROWSER/leave_session
                            rm -f $BROWSER/*

                        # close cityapp components
                            kill -9 $(pgrep -f ca_starter)

                            for i in $(pgrep -f cityapp);do
                                kill -9 $i
                            done

                            for i in $(pgrep -f inotifywait);do
                                kill -9 $i
                            done

                            kill -9 $(pgrep -f node)
                            
                        $MODULE/ca_starter.sh &
                        
                        Send_Message m 3 ca_restart.3 question actions [\"OK\"]
                            Request
                                exit
            else
                rm -f $MESSAGE_SENT/*
                exit
        fi
