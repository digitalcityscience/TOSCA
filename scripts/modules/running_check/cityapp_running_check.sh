#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.21
# CityApp module
#
# Core component, don not modify.
#
# This module is to send a message: the current module which has called this module, is still running.
#
# 2020. július 24.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/running_check
MODULE_NAME=cityapp_running_check
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
MESSAGE_SENT=~/cityapp/data_to_client


# -- processing -----

ID_NUM=1
MODULE_ORIGIN=$(cat $VARIABLES/module_status | head -n1)
RUNNING_MODULE=$(cat $VARIABLES/last_launched | head -n1)
while [ $(pgrep -f $RUNNING_MODULE) ];do
    RUNNING=$(cat $VARIABLES/module_status | tail -n1)
    echo $ID_NUM > $MESSAGE_SENT/$MODULE_ORIGIN".running"
    ID_NUM=$(($ID_NUM+1))
    sleep 0.8s
done
rm -f $MESSAGE_SENT/$MODULE_ORIGIN".running"
rm -f $VARIABLES/module_status
Close_Process
exit
