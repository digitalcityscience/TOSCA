#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 0.4
# CityApp module
# This module is to launch module_2b_query_process.sh, and process user communication
# 2020. július 26.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/module_2b
MODULE_NAME=module_2b
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_2b
MESSAGE_SENT=~/cityapp/data_to_client
GEOSERVER=~/cityapp/geoserver_data
GRASS=~/cityapp/grass/global
MAPSET=module_2
DATE_VALUE=$(date +%Y-%m-%d" "%H":"%M)
DATE_VALUE_2=$(date +%Y_%m_%d_%H_%M)

QUERY_RESOLUTION=0.00002

Running_Check start

##############
# Preprocess, 
##############
    
    rm -f $MESSAGE_SENT/*

    # First overwrite the region of module_2 mapset. If no such mapset exist, create it
        if [ -d $GRASS/$MAPSET ]
            then
                cp $GRASS/PERMANENT/WIND $GRASS/$MAPSET/WIND
            else
                mkdir $GRASS/$MAPSET
                cp -r ~/cityapp/grass/skel/* $GRASS/$MAPSET
                cp $GRASS/PERMANENT/WIND $GRASS/$MAPSET/WIND
        fi

        # RUNNING_MODE=$(cat $MODULE/mode)

#############
# User input
#############

    # If you want to draw a new query area, click 'Draw' button, draw the area you want to query, then click 'Save'. If you want to exit, click 'Cancel'.
        Send_Message m 1 module_2b.1 question actions [\"Draw\",\"Cancel\"]
            Request
            case $REQUEST_CONTENT in
                "draw"|"Draw"|"DRAW")
                    Request_Map geojson GEOJSON
                        Add_Vector $REQUEST_PATH query_area_1
                        Gpkg_Out query_area_1 query_area_1
                        sleep 1.1s
                     ;;
                "cancel"|"Cancel"|"CANCEL")
                    # To process exit, click OK.
                    Send_Message m 2 module_2b.2 question actions [\"OK\"]
                        Request
                            until [ "$REQUEST_CONTENT" == "ok" ]; do
                                rm -f $MESSAGE_SENT/*.message
                                Send_Message m 2 module_2b.2 question actions [\"OK\"]
                                    Request
                            done
                        Running_Check stop
                        Close_Process
                    exit;;
            esac

##############
#  Processing 
##############
    
    # Launching a separate script for actual calculations: this script will run directly in the GRASS GIS
        grass $GRASS/$MAPSET --exec ~/cityapp/scripts/modules/module_2b/module_2b_query_process.sh
        Send_Message m 2 module_2b.2 question actions [\"OK\"]
        
    # Creating the final pdf output
        # Writing numeric and map data into a single ods table file
            rm -f $MODULE/temp_result.ods
            ~/cityapp/scripts/external/csv2odf/csv2odf -S2 $MODULE/temp_outfile.csv $MODULE/template.ods $MODULE/temp_result.ods
        
        # Coverting ods into pdf
            rm -f $MODULE/temp_result.pdf
            cd $MODULE
            /usr/bin/soffice --convert-to pdf ./temp_result.ods

        # Merging table output pdf and maps pdf into a single pdf file
            gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=$MODULE/temp_results_$DATE_VALUE_2".pdf" $MODULE/temp_result.pdf $MODULE/temp_map_2.pdf
            
            cp $MODULE/temp_results_$DATE_VALUE_2".pdf" $MESSAGE_SENT/info.pdf
            cp $MODULE/temp_results_$DATE_VALUE_2".pdf" ~/cityapp/saved_results/bbswr_slum_landownership_query_$DATE_VALUE_2".pdf"
    
    # Query is finished, to process exit, click OK.
            Request
                until [ "$REQUEST_CONTENT" == "ok" ]; do
                    rm -f $MESSAGE_SENT/*.message
                    Send_Message m 2 module_2b.2 question actions [\"OK\"]
                        Request
                done

        Running_Check Stop
        Close_Process
    exit
