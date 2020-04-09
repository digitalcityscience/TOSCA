#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.32
# CityApp module
# This module is to shutdown cityapp system
#
# Core module, do not modify!
#
# 2020. április 9.
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
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/ca_shutdown
MESSAGE_SENT=~/cityapp/data_to_client

#
#-- Process -------------------
#

/usr/share/geoserver/bin/shutdown.sh

rm -f ~/cityapp/scripts/shared/temp/*
rm -f $MESSAGE_SENT/*
rm -f $VARIABLES/launcher_run
rm -f $VARIABLES/launch_locked
rm -f $BROWSER/leave_session
rm -f $BROWSER/*

kill -9 $(ps -a | grep ca_starter | sed s'/[a-z _]//'g | cut -d"/" -f1)

for i in $(ps -a | grep cityapp | sed s'/[a-z _]//'g | cut -d"/" -f1);do
    kill -9 $i
done

for i in $(ps a | grep "inotifywait" | grep "$USER" | cut -d" " -f1);do
    kill -9 $i
done

#for i in $(ps a | grep "node app.js" | grep -v grep | cut -d" " -f1);do
#    kill -9 $i
#done

Send_Message m 1 ca_shutdown.1 question actions [\"Yes\"]

exit
