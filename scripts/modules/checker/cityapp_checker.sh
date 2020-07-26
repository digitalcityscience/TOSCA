#! /bin/bash
# version 1.03
# CityApp maintenance
# Check requested components
# 2020. május 17.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany


# Checker has no frontend. It is used only at the installation to check if all the requeted components are available.
# Checker's messages are sent to the console the checker running in.

Running_Check start
ERROR=~/cityapp/error_log
rm -f $ERROR
touch $ERROR
 
if [ $(which inotifywait) ]
    then
        echo "inotifywait found"
    else
        echo "No inotifywait found" >> $ERROR
fi

if [ $(which grass) ]
    then
        echo "GRASS found"
    else
        echo "No GRASS found" >> $ERROR
fi

if [ $(which sed) ]
    then
        echo "sed found"
    else
        echo "No sed found" >> $ERROR
fi

if [ $(which cut) ]
    then
        echo "cut found"
    else
        echo "No cut found" >> $ERROR
fi

if [ $(which stat) ]
    then
        echo "stat found"
    else
        echo "No stat found" >> $ERROR
fi

if [ $(which head) ]
    then
        echo "head found"
    else
        echo "No head found" >> $ERROR
fi

if [ $(which tail) ]
    then
        echo "tail found"
    else
        echo "No tail found" >> $ERROR
fi

if [ $(which grep) ]
    then
        echo "grep found"
    else
        echo "No grep found" >> $ERROR
fi

if [ $(which enscript) ]
    then
        echo "enscript found"
    else
        echo "No enscript found" >> $ERROR
fi

if [ $( which ghostscript) ]
    then
        echo "ghostscript found"
    else
        echo "No ghostscript found" >> $ERROR
fi

if [ $(which gnuplot) ]
    then
        echo "gnuplot found"
    else
        echo "No gnuplot found" >> $ERROR
fi

if [ $(which node) ]
    then
        echo "node found"
    else
        echo "No node found" >> $ERROR
fi

if [ -e /usr/share/geoserver/bin/startup.sh ]
    then
        echo "geoserver found"
    else
        echo "No geoserver found" >> $ERROR
fi

if [ -e ~/cityapp/scripts/external/csv2odf/csv2odf ]
    then
        echo "csv2odf found"
    else
        echo "No csv2odf found" >> $ERROR
fi

if [ $(echo $(stat --printf="%s" $ERROR)) -eq 0 ]
then
    rm $ERROR
fi
Running_Check stop
exit
