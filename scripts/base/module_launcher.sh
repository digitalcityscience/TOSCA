#! /bin/bash
# version 1.0
# CityApp module
# This module is to check launcer.html
# when file "launch" exist, execute its content
# 2020. január 24.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

BROWSER=~/cityapp/data_from_browser

while inotifywait -e close_write $BROWSER/;do
    # filter out the last file
    # if "launch", read its content,
    # execute, then remove.

    FRESH=$(ls -ct1 $BROWSER/ | head -n1)
    if [ $(echo $FRESH | grep launch) ]
        then
            xterm -e $(cat $BROWSER/$FRESH) &
            rm -f $BROWSER/$(ls -ct1 $BROWSER/ | head -n1)
    fi
done
exit
