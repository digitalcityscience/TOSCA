#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.11
# CityApp module
# It is simply to touch "system.running" file in $MESSAGE_SENT directory
# Started by ca_starter and killed only by ca_shutdown
#
# Core module, do not modify.
#
# 2020. július 24.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#


cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/base
MODULE_NAME=cityapp_onesecond
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
MESSAGE_SENT=~/cityapp/data_to_client

VALUE=1
until [ $VALUE -eq 0 ];do
    echo $VALUE > $MESSAGE_SENT/system.running
    VALUE=$(($VALUE+1))
    sleep 0.8s
done

exit
