#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.21
# CityApp module
# This module is to query any existing map by a user-defined area
# 2020. április 13.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#


cd ~/cityapp

MODULES=~/cityapp/scripts/modules
MODULE=~/cityapp/scripts/modules/module_2
MODULE_NAME=module_2
VARIABLES=~/cityapp/scripts/shared/variables
BROWSER=~/cityapp/data_from_browser
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang)
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_2
MESSAGE_SENT=~/cityapp/data_to_client
GEOSERVER=~/cityapp/geoserver_data
GRASS=~/cityapp/grass/global
MAPSET=module_2

QUERY_RESOLUTION=0.00001

Running_Check start

#
#-- Preprocess, User dialogues -------------------
#

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

# Message 1 Draw an area to query
    Send_Message m 1 module_2.1 question actions [\"OK\"]
        Request_Map geojson
            QUERY_AREA=$REQUEST_PATH
            
            # copy for archiving -- later, when a saving is not requested, it will deleted
            cp $REQUEST_PATH $MODULE/temp_storage/query_area

            Process_Check start add_map
            Add_Vector $QUERY_AREA query_area_1
            QUERY_AREA="query_area_1"
            
            Gpkg_Out query_area_1 query_area_1
            Process_Check stop add_map
            
# Message 2 Maps of PERMANENT mapset can only be queryed. Default maps and "selection" map is not included in the list. Only map with numeric column (except column "CAT") will listed. What is the map you want to query? Available maps are:
    grass $GRASS/$MAPSET --exec $MODULE/cityapp_module_2_listing.sh
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
            
            # query map topology
            Topology $GRASS/$MAPSET $MAP_TO_QUERY
            # Topology is now stored in variable MAP_TOPOLOGY -- later this would useful.

# Message 3 Fill the form and press save.
    # Supporting only integer and double precision type fields to query, except: CAT
    grass $GRASS/$MAPSET --exec db.describe -c table=$MAP_TO_QUERY | grep -E 'DOUBLE\ PRECISION|INTEGER' | grep -vE 'CAT|cat' > $MODULE/temp_columns


    Send_Message l 3 module_2.3 select actions [\"OK\"] $MODULE/temp_columns
        Request
            echo $REQUEST_CONTENT > $MODULE/temp_storage/query_request

            Process_Check start calculations
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

# Clip the basemep map by query area
    grass $GRASS/$MAPSET --exec v.select ainput=$MAP_TO_QUERY atype=point,line,boundary,centroid,area binput=$QUERY_AREA  btype=area output=clipped operator=overlap --overwrite

# Applying the query request
    QUERY_REQUEST=$(cat $MODULE/temp_storage/query_request | sed s'/"//'g | sed s'/,//'g | sed s'/\[//'g | sed s'/\]//'g | cut -d" " -f4-)
    grass $GRASS/$MAPSET --exec v.extract  input=clipped where="$QUERY_REQUEST" output=query_result_1 --overwrite

#Query statistics
    COLUMN_TO_QUERY=$(cat $MODULE/temp_storage/query_request | sed s'/"//'g | sed s'/,//'g | sed s'/\[//'g | sed s'/\]//'g | cut -d" " -f3)
    grass $GRASS/$MAPSET --exec v.db.univar -e -g map=query_result_1 column=$COLUMN_TO_QUERY | cut -d"=" -f2 > $MODULE/temp_statistic

# Data output
    Gpkg_Out query_result_1 query_result_1

    rm -f $MODULE/temp_storage/statistics_output
    touch $MODULE/temp_storage/statistics_output
        echo "{" > $MODULE/temp_storage/statistics_output
        echo "\"text\":" >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MESSAGE_TEXT | head -n19 | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"modalType\": \"results\"," >> $MODULE/temp_storage/statistics_output
        echo "\"actions\": [\"Close\"]," >> $MODULE/temp_storage/statistics_output
        echo "\"list\":" >> $MODULE/temp_storage/statistics_output
        echo "{" >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MESSAGE_TEXT | head -n20 | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MODULE/temp_storage/query_request | sed s'/"//'g  | sed s'/ //'g | sed s'/,>,/>/'g | sed s'/,<,/</'g | sed s'/,=,/=/'g | sed s'/,/ /'g | sed s'/\[ //'g | sed s'/\ ]//'g | cut -d" " -f1)\"," >> $MODULE/temp_storage/statistics_output
        echo "" >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MESSAGE_TEXT | head -n21 | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MODULE/temp_storage/query_request | sed s'/"//'g  | sed s'/ //'g | sed s'/,>,/>/'g | sed s'/,<,/</'g | sed s'/,=,/=/'g | sed s'/,/ /'g | sed s'/\[ //'g | sed s'/\ ]//'g | cut -d" " -f2-)\"," >> $MODULE/temp_storage/statistics_output
        echo "" >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MESSAGE_TEXT | head -n22 | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "" >> $MODULE/temp_storage/statistics_output
        
        echo "\"$(head -n4 < $MESSAGE_TEXT | tail -n1)" "$(head -n1 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n5 < $MESSAGE_TEXT | tail -n1)" "$(head -n10 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output 
        echo "\"$(head -n6 < $MESSAGE_TEXT | tail -n1)" "$(head -n2 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output 
        echo "\"$(head -n7 < $MESSAGE_TEXT | tail -n1)" "$(head -n3 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output 
        echo "\"$(head -n8 < $MESSAGE_TEXT | tail -n1)" "$(head -n4 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n9 < $MESSAGE_TEXT | tail -n1)" "$(head -n5 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n10 < $MESSAGE_TEXT | tail -n1)" "$(head -n12 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n11 < $MESSAGE_TEXT | tail -n1)" "$(head -n6 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n12 < $MESSAGE_TEXT | tail -n1)" "$(head -n8 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n13 < $MESSAGE_TEXT | tail -n1)" "$(head -n7 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n14 < $MESSAGE_TEXT | tail -n1)" "$(head -n9 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n15 < $MESSAGE_TEXT | tail -n1)" "$(head -n11 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n17 < $MESSAGE_TEXT | tail -n1)" "$(head -n13 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n18 < $MESSAGE_TEXT | tail -n1)" "$(head -n14 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "}" >> $MODULE/temp_storage/statistics_output
        echo "}" >> $MODULE/temp_storage/statistics_output
    Process_Check stop calculations
    
    rm -f $MESSAGE_SENT/*.message
    cp $MODULE/temp_storage/statistics_output $MESSAGE_SENT/module_2.4message
        Request
        Running_Check stop
        Close_Process

exit

---------

# From here it is an other version, with raster-based analysis (it is faster, but not as flexible as the other)


# Message 1 Draw an area to query
    Send_Message m 1 module_2.1 question actions [\"OK\"]
        Request_Map geojson
            QUERY_AREA=$REQUEST_PATH
            
            # copy for archiving -- later, when a saving is not requested, it will deleted
            cp $REQUEST_PATH $MODULE/temp_storage/query_area

            Process_Check start add_map
            Add_Vector $QUERY_AREA query_area_1
            QUERY_AREA="query_area_1"
            
            Gpkg_Out query_area_1 query_area_1
            Process_Check stop add_map
            
# Message 2 Maps of PERMANENT mapset can only be queryed. Default maps and "selection" map is not included in the list. Only map with numeric column (except column "CAT") will listed. What is the map you want to query? Available maps are:
    grass $GRASS/$MAPSET --exec $MODULE/cityapp_module_2_listing.sh
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
            
            # query map topology
            Topology $GRASS/$MAPSET $MAP_TO_QUERY
            # Topology is now stored in variable MAP_TOPOLOGY -- later this would useful.

# Message 3 Fill the form and press save.
    # Supporting only integer and double precision type fields to query, except: CAT
    grass $GRASS/$MAPSET --exec db.describe -c table=$MAP_TO_QUERY | grep -E 'DOUBLE\ PRECISION|INTEGER' | grep -vE 'CAT|cat' > $MODULE/temp_columns


    Send_Message l 3 module_2.3 select actions [\"OK\"] $MODULE/temp_columns
        Request
            echo $REQUEST_CONTENT > $MODULE/temp_storage/query_request

            Process_Check start calculations
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


    rm -f $MODULE/temp_storage/statistics_output
    touch $MODULE/temp_storage/statistics_output
        echo "{" > $MODULE/temp_storage/statistics_output
        echo "\"text\":" >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MESSAGE_TEXT | head -n19 | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"modalType\": \"results\"," >> $MODULE/temp_storage/statistics_output
        echo "\"actions\": [\"Close\"]," >> $MODULE/temp_storage/statistics_output
        echo "\"list\":" >> $MODULE/temp_storage/statistics_output
        echo "{" >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MESSAGE_TEXT | head -n20 | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MODULE/temp_storage/query_request | sed s'/"//'g  | sed s'/ //'g | sed s'/,>,/>/'g | sed s'/,<,/</'g | sed s'/,=,/=/'g | sed s'/,/ /'g | sed s'/\[ //'g | sed s'/\ ]//'g | cut -d" " -f1)\"," >> $MODULE/temp_storage/statistics_output
        echo "" >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MESSAGE_TEXT | head -n21 | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MODULE/temp_storage/query_request | sed s'/"//'g  | sed s'/ //'g | sed s'/,>,/>/'g | sed s'/,<,/</'g | sed s'/,=,/=/'g | sed s'/,/ /'g | sed s'/\[ //'g | sed s'/\ ]//'g | cut -d" " -f2-)\"," >> $MODULE/temp_storage/statistics_output
        echo "" >> $MODULE/temp_storage/statistics_output
        echo "\"$(cat $MESSAGE_TEXT | head -n22 | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "" >> $MODULE/temp_storage/statistics_output
        
        echo "\"$(head -n4 < $MESSAGE_TEXT | tail -n1)" "$(head -n6 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n5 < $MESSAGE_TEXT | tail -n1)" "$(head -n15 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output 
        echo "\"$(head -n6 < $MESSAGE_TEXT | tail -n1)" "$(head -n7 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output 
        echo "\"$(head -n7 < $MESSAGE_TEXT | tail -n1)" "$(head -n8 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output 
        echo "\"$(head -n8 < $MESSAGE_TEXT | tail -n1)" "$(head -n9 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n9 < $MESSAGE_TEXT | tail -n1)" "$(head -n10 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n10 < $MESSAGE_TEXT | tail -n1)" "$(head -n17 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n11 < $MESSAGE_TEXT | tail -n1)" "$(head -n11 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n12 < $MESSAGE_TEXT | tail -n1)" "$(head -n12 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n13 < $MESSAGE_TEXT | tail -n1)" "$(head -n13 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n14 < $MESSAGE_TEXT | tail -n1)" "$(head -n14 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n15 < $MESSAGE_TEXT | tail -n1)" "$(head -n16 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n16 < $MESSAGE_TEXT | tail -n1)" "$(head -n17 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n17 < $MESSAGE_TEXT | tail -n1)" "$(head -n18 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "\"$(head -n18 < $MESSAGE_TEXT | tail -n1)" "$(head -n19 < $MODULE/temp_statistic | tail -n1)\"," >> $MODULE/temp_storage/statistics_output
        echo "}" >> $MODULE/temp_storage/statistics_output
        echo "}" >> $MODULE/temp_storage/statistics_output
    Process_Check stop calculations
    
    rm -f $MESSAGE_SENT/*.message
    cp $MODULE/temp_storage/statistics_output $MESSAGE_SENT/module_2.4message
        Request
        Running_Check stop
        Close_Process
        
