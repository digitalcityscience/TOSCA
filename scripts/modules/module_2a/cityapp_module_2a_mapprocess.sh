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

#############
# Preprocess
#############

MAP_TO_QUERY=$(cat $MODULE/temp_map_to_query)
QUERY_AREA=query_area
WHERE=$(cat $MODULE/temp_where)
QUERY_COLUMN=$(cat $MODULE/temp_query_column)

#############
# Processing
#############

    ID_NUM=1
    for i in $(g.list type=vector | grep "query_area_"[0-5]);do
        v.select ainput=$MAP_TO_QUERY atype=point,line,boundary,centroid,area binput=$i btype=area output=clipped_$ID_NUM operator=overlap --overwrite 
        v.extract  input=clipped_$ID_NUM where="$WHERE" output=query_result_area_$ID_NUM --overwrite
        v.db.univar -e -g map=query_result_area_$ID_NUM column=$QUERY_COLUMN | cut -d"=" -f2 > $MODULE/temp_statistics_$ID_NUM
        ID_NUM=$(($ID_NUM+1))
    done

exit




    ID_NUM=1
    for i in $(g.list type=vector | grep "query_area_"[0-5]);do
        touch "grass stage 0 ID_NUM: $ID_NUM"
        # Clip the basemep map by query area
        v.select ainput=$MAP_TO_QUERY atype=point,line,boundary,centroid,area binput=$i btype=area output=clipped_$ID_NUM operator=overlap --overwrite &
        ID_NUM=$(($ID_NUM+1))
    done

    ID_NUM=1
    for i in $(g.list type=vector | grep "clipped_"[0-5]);do
        # Applying the query request
        touch "grass stage 0 ID_NUM: $ID_NUM"
        v.extract  input=$i where="$WHERE" output=query_result_area_$ID_NUM --overwrite
        ID_NUM=$(($ID_NUM+1))
    done
        
    for i in $(g.list type=vector | grep "query_result_area_"[0-5]);do
        #Query statistics
        touch "grass stage 0 ID_NUM: $ID_NUM"
        v.db.univar -e -g map=$i column=$QUERY_COLUMN | cut -d"=" -f2 > $MODULE/temp_statistics_$ID_NUM
        ID_NUM=$(($ID_NUM+1))
    done

