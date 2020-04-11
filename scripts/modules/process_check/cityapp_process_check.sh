#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.1
# CityApp module
#
# Core component, don not modify.
#
# This module is to send a message: the last process is still running.
#
# 2020. április 9.
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
PROCESS_ORIGIN=$(cat $VARIABLES/process_status | head -n1)
RUNNING=$(cat $VARIABLES/process_status | tail -n1)
while [ $RUNNING -eq 1 ];do
    RUNNING=$(cat $VARIABLES/process_status | tail -n1)
    echo $ID_NUM > $MESSAGE_SENT/$PROCESS_ORIGIN".processing"
    ID_NUM=$(($ID_NUM+1))
    sleep 1s
done
rm -f $MESSAGE_SENT/$PROCESS_ORIGIN".processing"
rm -f $VARIABLES/process_status
exit
