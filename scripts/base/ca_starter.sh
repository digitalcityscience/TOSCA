#! /bin/bash
. ~/cityapp/scripts/shared/functions

# version 1.3
# CityApp module
# This module is to start cityapp system
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
MODULE_NAME=ca_starter
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/ca_starter
MESSAGE_SENT=~/cityapp/data_to_client
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)

#
#-- Process -------------------
#

for i in $(ps -a | grep cityapp | sed s'/[a-z _]//'g | cut -d"/" -f1);do
    echo $i
    kill -9 $i
done

for i in $(ps -a | grep inotifywait | sed s'/[a-z _]//'g | cut -d"/" -f1);do
    echo $i
    kill -9 $i
done

cd  ~/cityapp
~/cityapp/scripts/base/cityapp_module_launcher.sh

exit
