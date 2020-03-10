#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.3
# CityApp module
# This module is to shutdown cityapp system
#
# Core module, do not modify!
#
# 2020. március 6.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/base
MODULE_NAME=ca_shutdown
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/ca_shutdown
MESSAGE_SENT=~/cityapp/data_to_client
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)

#
#-- Process -------------------
#

rm -f ~/cityapp/scripts/shared/temp/*
rm -f $MESSAGE_SENT/*
rm -f $VARIABLES/launcher_run
rm -f $VARIABLES/launch_locked
rm -f $BROWSER/leave_session
rm -f $BROWSER/*

kill -9 $(ps -a | grep ca_starter | sed s'/[a-z _]//'g | cut -d"/" -f1)

for i in $(ps -a | grep cityapp | sed s'/[a-z _]//'g | cut -d"/" -f1);do
    echo $i
    kill -9 $i
done

for i in $(ps -a | grep inotifywait | sed s'/[a-z _]//'g | cut -d"/" -f1);do
    echo $i
    kill -9 $i
done

Send_Message m 1 ca_shutdown.1 question actions [\"Yes\"]
exit
