#! /bin/bash
. ~/cityapp/scripts/shared/functions

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

#felirat 4
#adat 6
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
cat $MESSAGE_TEXT | head -n6 | tail -n1 >> $MODULE/temp_storage/statistic_1
cat $MODULE/temp_statistic | head -n$k | tail -n1 >> $MODULE/temp_storage/statistic_1
