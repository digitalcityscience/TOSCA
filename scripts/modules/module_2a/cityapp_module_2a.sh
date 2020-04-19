#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.0
# CityApp module
# This module is to comparing many area on the same map and criterias
# 2020. április 18.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/module_2a
MODULE_NAME=module_2a
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_2a
MESSAGE_SENT=~/cityapp/data_to_client
GEOSERVER=~/cityapp/geoserver_data
GRASS=~/cityapp/grass/global
MAPSET=module_2
DATE_VALUE=$(date +%Y-%m-%d" "%H":"%M)
DATE_VALUE_2=$(date +%Y_%m_%d_%H_%M)

QUERY_RESOLUTION=0.00002

Running_Check start

#############
# Preprocess
#############

    # It would great to make a distinction if the queried map is point, line, or polygon type?
    # If points > 0 AND lines = 0 AND centroids = 0: point
    # If points = 0 AND lines > 0 AND centroids = 0: line
    # If points = 0 AND lines = 0 AND centroids > 0: area (polygon)

    # If line type map, only lenght in meters can be queryed
    # for point and area map any other value can be queryed
    # What if to query topology data too? (area, lenght?)

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

#################################################
# Load parameters: area to query, map, critrias. 
#################################################

    ORDER_VALUE=1
    CONTINUE=yes
    until [ "$CONTINUE" == "no" -o $ORDER_VALUE -eq 6 ];do
        # Message 1 Draw an area to query
            Send_Message m 1 module_2a.1 question actions [\"OK\"]
                Request_Map geojson
                    QUERY_AREA=$REQUEST_PATH
                    Add_Vector $QUERY_AREA query_area_$ORDER_VALUE
                # Message 1 Do you want to add further query area?
                Send_Message m 2 module_2a.2 question actions [\"yes\",\"no\"]
                    Request
                        CONTINUE=$REQUEST_CONTENT
                        ORDER_VALUE=$(($ORDER_VALUE+1))
    done
    
    THREADS=$(($ORDER_VALUE-1))
    
    # Message 3 Maps of PERMANENT mapset can only be queryed. Default maps and "selection" map is not included in the list. Only map with numeric column (except column "CAT") will listed. What is the map you want to query? Available maps are:
        grass $GRASS/$MAPSET --exec $MODULE/cityapp_module_2_listing.sh
        Send_Message l 3 module_2a.3 select actions [\"OK\"] $MODULE/temp_maps
            Request
                MAP_TO_QUERY=$REQUEST_CONTENT
                echo $MAP_TO_QUERY > $MODULE/temp_map_to_query

                # Now it is possible to chechk if the map to query is in the default mapset (set in the header as MAPSET), or not. If not, the map has to be copied into the module_2 mapset and the further processes will taken in this mapset.
                
                if [ $(grass $GRASS/$MAPSET --exec g.list type=vector mapset=module_2 | grep "$MAP_TO_QUERY") ]
                    then
                        echo ""
                    else
                        grass $GRASS/$MAPSET --exec g.copy vector=$MAP_TO_QUERY"@"PERMANENT,$MAP_TO_QUERY
                fi
                
                # query map topology
                Topology $GRASS/$MAPSET $MAP_TO_QUERY
                # Topology is now stored in variable MAP_TOPOLOGY -- later this would useful.

    # Message 4 Fill the form and press save.
        # Supporting only integer and double precision type fields to query, except: CAT
        grass $GRASS/$MAPSET --exec db.describe -c table=$MAP_TO_QUERY | grep -E 'DOUBLE\ PRECISION|INTEGER' | grep -vE 'CAT|cat' > $MODULE/temp_columns
        Send_Message l 4 module_2a.4 select actions [\"OK\"] $MODULE/temp_columns
            Request
                echo $REQUEST_CONTENT > $MODULE/temp_query_request

                Json_To_Text $MODULE/temp_query_request $MODULE/query_request_temp

                QUERY_COLUMN=$(cat $MODULE/query_request_temp | cut -d"," -f2)
                echo $QUERY_COLUMN > $MODULE/temp_query_column

                WHERE_COLUMN_1=$(cat $MODULE/query_request_temp | cut -d"," -f3)
                RELATION_1=$(cat $MODULE/query_request_temp | cut -d"," -f4)
                VALUE_1=$(cat $MODULE/query_request_temp | cut -d"," -f5)

                LOGICAL_1=$(cat $MODULE/query_request_temp | cut -d"," -f6)

                WHERE_COLUMN_2=$(cat $MODULE/query_request_temp | cut -d"," -f7)
                RELATION_2=$(cat $MODULE/query_request_temp | cut -d"," -f8)
                VALUE_2=$(cat $MODULE/query_request_temp | cut -d"," -f9)

                LOGICAL_2=$(cat $MODULE/query_request_temp | cut -d"," -f10)

                WHERE_COLUMN_3=$(cat $MODULE/query_request_temp | cut -d"," -f11)
                RELATION_3=$(cat $MODULE/query_request_temp | cut -d"," -f12)
                VALUE_3=$(cat $MODULE/query_request_temp | cut -d"," -f13)

                WHERE=$(echo $WHERE_COLUMN_1 $RELATION_1 $VALUE_1 $LOGICAL_1 $WHERE_COLUMN_2 $RELATION_2 $VALUE_2 $LOGICAL_2 $WHERE_COLUMN_3 $RELATION_3 $VALUE_3 | sed s'/,//'g)
                echo $WHERE > $MODULE/temp_where


##################################################################################
# Processing -- paralell processing: one thread for each area.
# After each therad finished the process, comarision and creating a single output 
##################################################################################
    
    # Set region to selection, set resolution
    grass $GRASS/$MAPSET --exec g.region vector=selection@PERMANENT res=$QUERY_RESOLUTION --overwrite

    Process_Check start calculations
        grass -f $GRASS/$MAPSET --exec $MODULE/cityapp_module_2a_mapprocess.sh
    Process_Check stop calculations
exit


















            # Data output
                Gpkg_Out query_result_area_1 query_result_area_1

                rm -f $MODULE/temp_statistics_output_1
                touch $MODULE/temp_statistics_output_1
                    
                    echo $(cat $MESSAGE_TEXT | head -n22 | tail -n1) > $MODULE/temp_statistics_output_1
                    cat $MESSAGE_TEXT | head -n23 | tail -n1 >> $MODULE/temp_statistics_output_1
                    echo $DATE_VALUE >> $MODULE/temp_statistics_output_1
                    echo " " >> $MODULE/temp_statistics_output_1
                    cat $MESSAGE_TEXT | head -n24 | tail -n1 >> $MODULE/temp_statistics_output_1
                    cat $MODULE/temp_storage/query_request | sed s'/"//'g  | sed s'/ //'g | sed s'/,>,/>/'g | sed s'/,<,/</'g | sed s'/,=,/=/'g | sed s'/,/ /'g | sed s'/\[ //'g | sed s'/\ ]//'g | cut -d" " -f1 >> $MODULE/temp_statistics_output_1
                    echo " " >> $MODULE/temp_statistics_output_1
                    cat $MESSAGE_TEXT | head -n25 | tail -n1  >> $MODULE/temp_statistics_output_1
                    cat $MODULE/temp_storage/query_request | sed s'/"//'g  | sed s'/ //'g | sed s'/,>,/>/'g | sed s'/,<,/</'g | sed s'/,=,/=/'g | sed s'/,/ /'g | sed s'/\[ //'g | sed s'/\ ]//'g | cut -d" " -f2- >> $MODULE/temp_statistics_output_1
                    echo " " >> $MODULE/temp_statistics_output_1
                    cat $MESSAGE_TEXT | head -n26 | tail -n1 >> $MODULE/temp_statistics_output_1
                    echo " " >> $MODULE/temp_statistics_output_1
                    
                    echo "$(head -n7 < $MESSAGE_TEXT | tail -n1)" "$(head -n1 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1
                    echo "$(head -n8 < $MESSAGE_TEXT | tail -n1)" "$(head -n10 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1 
                    echo "$(head -n9 < $MESSAGE_TEXT | tail -n1)" "$(head -n2 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1 
                    echo "$(head -n10 < $MESSAGE_TEXT | tail -n1)" "$(head -n3 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1 
                    echo "$(head -n11 < $MESSAGE_TEXT | tail -n1)" "$(head -n4 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1
                    echo "$(head -n12 < $MESSAGE_TEXT | tail -n1)" "$(head -n5 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1
                    echo "$(head -n13 < $MESSAGE_TEXT | tail -n1)" "$(head -n12 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1
                    echo "$(head -n14 < $MESSAGE_TEXT | tail -n1)" "$(head -n6 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1
                    echo "$(head -n15 < $MESSAGE_TEXT | tail -n1)" "$(head -n8 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1
                    echo "$(head -n16 < $MESSAGE_TEXT | tail -n1)" "$(head -n7 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1
                    echo "$(head -n17 < $MESSAGE_TEXT | tail -n1)" "$(head -n9 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1
                    echo "$(head -n18 < $MESSAGE_TEXT | tail -n1)" "$(head -n11 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1
                    echo "$(head -n20 < $MESSAGE_TEXT | tail -n1)" "$(head -n13 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1
                    echo "$(head -n21 < $MESSAGE_TEXT | tail -n1)" "$(head -n14 < $MODULE/temp_statistics_1 | tail -n1)" >> $MODULE/temp_statistics_output_1
                
                rm -f $MESSAGE_SENT/*.message
                cp $MODULE/temp_statistics_output_1 $MESSAGE_SENT/module_2.1.info
                
                    cat $MODULE/temp_statistics_output_1 | sed s'/"//'g | sed s'/{//'g | sed s'/}//'g > $MODULE/temp_statistics_text_1
                    enscript -p $MODULE/temp_statistics_1.ps $MODULE/temp_statistics_text_1
                    ps2pdf $MODULE/temp_statistics_1.ps $MODULE/temp_statistics_1.pdf
                
                    grass $GRASS/$MAPSET --exec ps.map input=$MODULE/ps_param_1 output=$MODULE/temp_query_map_1.ps --overwrite
                    ps2pdf $MODULE/temp_query_map_1.ps $MODULE/temp_query_map_1.pdf

                    gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=$MODULE/temp_query_results_$DATE_VALUE_2".pdf" $MODULE/temp_statistics_1.pdf $MODULE/temp_query_map_1.pdf
                    
                    mv $MODULE/temp_query_results_$DATE_VALUE_2".pdf" ~/cityapp/saved_results/query_results_$DATE_VALUE_2".pdf"
                
                Send_Message m 28 module_2.4 question actions [\"yes\",\"no\"]
                    Request
                        SIMPLE_OR_COMPARE=$REQUEST_CONTENT
                            if [ "$SIMPLE_OR_COMPARE"=="no" ]
                                then
                                    Send_Message m 27 module_2.5 question actions [\"OK\"]
                                        Request
                                        Running_Check stop
                                        Close_Process
                                        exit
                            fi
                            if [ "$SIMPLE_OR_COMPARE"=="yes" ]
                                then
                                    COMPARE_MODE="yes"
                            fi
           
    Running_Check stop
    Close_Process
exit
