#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.2
# CityApp module
# This module is to query any existing map by a user-defined area
# 2020. február 5.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

GEOSERVER=~/cityapp/geoserver_data
MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/module_2
GRASS=~/cityapp/grass/global
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_2
MESSAGE_SENT=~/cityapp/data_to_client
MAPSET=module_2

QUERY_RESOLUTION=0.00003

#
#-- Preprocess, User dialogues -------------------
#

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

# Message 1 Draw an area to query
    Send_Message m 1 module_2.1 question actions [\"OK\"]
        Request_Map geojson
            QUERY_AREA=$REQUEST_PATH
            
            # copy for archiving -- later, when a saving is not requested, it will deleted
            cp $REQUEST_PATH $MODULE/temp_storage/query_area

            Add_Vector $QUERY_AREA query_area_1
            QUERY_AREA="query_area_1"
            
            Gpkg_Out query_area_1 query_area_1
    
# Message 2 Only can query maps of PERMANENT mapset. What is the map you want to query? Available maps are:
    grass $GRASS/$MAPSET --exec g.list mapset=PERMANENT type=vector > $MODULE/temp_maps
    Send_Message l 2 module_2.2 select actions [\"OK\"] $MODULE/temp_maps
        Request
            MAP_TO_QUERY=$REQUEST_CONTENT
            # copy for achiving
            echo $MAP_TO_QUERY > $MODULE/temp_storage/map_to_query

            # Now it is possible to chechk if the map to query is in the default mapset (set in the header as MAPSET), or not. If not, the map has to be copied into the module_2 mapset and the further processes will taken in this mapset.
            
            if [ grass $GRASS/$MAPSET --exec g.list type=vector mapset=module_2 | grep "$MAP_TO_QUERY" ]
                then
                    echo ""
                else
                    grass $GRASS/$MAPSET --exec g.copy vector=$MAP_TO_QUERY"@"PERMANENT,$MAP_TO_QUERY
            fi

# Message 3 Fill the form and press save.
    grass $GRASS/$MAPSET --exec db.columns table=$MAP_TO_QUERY > $MODULE/temp_columns
    Send_Message l 3 module_2.3 select actions [\"OK\"] $MODULE/temp_columns
        Request
            echo $REQUEST_CONTENT > $MODULE/temp_storage/query_request

            Json_To_Text $MODULE/temp_storage/query_request $MODULE/temp_request

            QUERY_COLUMN_A=$(cat $MODULE/temp_request | cut -d"," -f2)

            WHERE_COLUMN_1=$(cat $MODULE/temp_request | cut -d"," -f3)
            RELATION_1=$(cat $MODULE/temp_request | cut -d"," -f4)
            VALUE_1=$(cat $MODULE/temp_request | cut -d"," -f5)

            LOGICAL_1=$(cat $MODULE/temp_request | cut -d"," -f6)

            WHERE_COLUMN_2=$(cat $MODULE/temp_request | cut -d"," -f7)
            RELATION_2=$(cat $MODULE/temp_request | cut -d"," -f8)
            VALUE_2=$(cat $MODULE/temp_request | cut -d"," -f9)

            LOGICAL_2=$(cat $MODULE/temp_request | cut -d"," -f10)

            WHERE_COLUMN_3=$(cat $MODULE/temp_request | cut -d"," -f11)
            RELATION_3=$(cat $MODULE/temp_request | cut -d"," -f12)
            VALUE_3=$(cat $MODULE/temp_request | cut -d"," -f13)

            WHERE=$(echo $WHERE_COLUMN_1 $RELATION_1 $VALUE_1 $LOGICAL_1 $WHERE_COLUMN_2 $RELATION_2 $VALUE_2 $LOGICAL_2 $WHERE_COLUMN_3 $RELATION_3 $VALUE_3 | sed s'/,//'g)
    
    
# Set region to query area, set resolution
    grass $GRASS/$MAPSET --exec g.region vector=$MAP_TO_QUERY res=$QUERY_RESOLUTION --overwrite

# Set MASK to query area
    grass $GRASS/$MAPSET --exec r.mask vector=$QUERY_AREA --overwrite

# Selecting only centroids of area map
    grass $GRASS/$MAPSET --exec v.select -t --overwrite ainput=$MAP_TO_QUERY atype=centroid binput=$QUERY_AREA output=$MAP_TO_QUERY"_centroid" operator=overlap

# Transform query map in raster format, where $CRITERIA (what if "no"?) value=attr attr field=COLUMN_TO_QUERY
    grass $GRASS/$MAPSET --exec v.to.rast input=$MAP_TO_QUERY type=centroid where="$WHERE" output=$MAP_TO_QUERY"_raster" use=attr attribute_column=$QUERY_COLUMN_A --overwrite --quiet
    
# Use Update datatable by raster under centroid -- print only
    grass $GRASS/$MAPSET --exec v.what.rast -p map=$MAP_TO_QUERY"_centroid" type=centroid raster=$MAP_TO_QUERY"_raster" > $MODULE/temp_query_result

# Data output
    grass $GRASS/$MAPSET --exec r.univar -e map=$MAP_TO_QUERY"_raster" | cut -d":" -f2 | sed 's/ //g' > $MODULE/temp_statistic
    grass $GRASS/$MAPSET --exec r.stats -c -n input=$MAP_TO_QUERY"_raster" separator=comma sort=asc --quiet > $MODULE/temp_histo
    # Export raster to vector
    grass $GRASS/$MAPSET --exec r.to.vect -t input=$MAP_TO_QUERY"_raster" output=query_result_1 type=point --overwrite
    Gpkg_Out query_result_1 query_result_1


    rm -f $MODULE/temp_storage/statistic_1
    touch $MODULE/temp_storage/statistic_1

    echo $(head -n4 < $MESSAGE_TEXT | tail -n1)" "$(head -n6 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    echo $(head -n5 < $MESSAGE_TEXT | tail -n1)" "$(head -n15 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1 
    echo $(head -n6 < $MESSAGE_TEXT | tail -n1)" "$(head -n7 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1 
    echo $(head -n7 < $MESSAGE_TEXT | tail -n1)" "$(head -n8 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1 
    echo $(head -n8 < $MESSAGE_TEXT | tail -n1)" "$(head -n9 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    echo $(head -n9 < $MESSAGE_TEXT | tail -n1)" "$(head -n10 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    echo $(head -n10 < $MESSAGE_TEXT | tail -n1)" "$(head -n17 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    echo $(head -n11 < $MESSAGE_TEXT | tail -n1)" "$(head -n11 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    echo $(head -n12 < $MESSAGE_TEXT | tail -n1)" "$(head -n12 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    echo $(head -n13 < $MESSAGE_TEXT | tail -n1)" "$(head -n13 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    echo $(head -n14 < $MESSAGE_TEXT | tail -n1)" "$(head -n14 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    echo $(head -n15 < $MESSAGE_TEXT | tail -n1)" "$(head -n16 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    echo $(head -n16 < $MESSAGE_TEXT | tail -n1)" "$(head -n17 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    echo $(head -n17 < $MESSAGE_TEXT | tail -n1)" "$(head -n18 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    echo $(head -n18 < $MESSAGE_TEXT | tail -n1)" "$(head -n19 < $MODULE/temp_statistic | tail -n1) >> $MODULE/temp_storage/statistic_1
    
exit
