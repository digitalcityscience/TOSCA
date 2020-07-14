#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 0.31
# CityApp module
# This module is to query any existing map by a user-defined area -- querying attribute data only
# 2020. júliu 2.
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

# Draw an area to query or select an existing one -- OK
# What is the map containing population data? -- OK
# what is the column you want to use as population data
# What is the map containing land ownership?
# what is the column you want use as ownership data
# Do you want to set these values as default?

Running_Check start



##############
# Preprocess, 
##############

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

        # RUNNING_MODE=$(cat $MODULE/mode)

#############
# User input
#############

    #  If you want to use an existing map as query area, click 'Map' button, then draw the area, and click 'Save'.  If you want to draw a new query area, click 'Draw' button. If you want to exit, click 'Cancel'.
        Send_Message m 1 module_2b.1 question actions [\"Map\",\"Draw\",\"Cancel\"]
            Request
            case $REQUEST_CONTENT in
                "map"|"Map"|"MAP")
                
                    # First creating a list of available maps, non including basemaps
                    rm -f $MODULE/temp_maps
                    touch $MODULE/temp_maps
                    for i in $(grass $GRASS/$MAPSET --exec g.list mapset=PERMANENT type=vector | grep -vE 'lines_osm|lines|points_osm|polygons_osm|polygons|relations_osm|relations|selection'); do
                        echo $i >> $MODULE/temp_maps
                    done
                    
                    # Now user can select a map
                    # Message 2 Select a map. Avilable maps are:
                    Send_Message l 2 module_2b.2 select actions [\"Yes\"] $MODULE/temp_maps
                        Request
                            QUERY_AREA_1=$REQUEST_CONTENT
                    ;;
                "draw"|"Draw"|"DRAW")
                    Request_Map geojson GEOJSON
                    
                        Process_Check start add_map
                        Add_Vector $REQUEST_PATH query_area_1
                        Gpkg_Out query_area_1
                        QUERY_AREA_1=query_area_1
                    
                        Process_Check stop add_map
                     ;;
                "cancel"|"Cancel"|"CANCEL")
                    # To process exit, click OK.
                    Send_Message m 3 module_2b.3 question actions [\"OK\"]
                        Request
                        Running_Check stop
                        Close_Process
                    exit;;
            esac
            
        # Refreshing the map selection in the saved_query_settings file
            
       #     MAP_TO_QUERY_POPULATION=$(cat $MODULE/saved_query_settings | head -n1)
       #     COLUMN_POPULATION=$(cat $MODULE/saved_query_settings | head -n2 | tail -n1)
       #     MAP_TO_QUERY_OWNERSHIP=$(cat $MODULE/saved_query_settings | head -n3 | tail -n1)
       #     COLUMN_OWNERSHIP=$(cat $MODULE/saved_query_settings | head -n4 | tail -n1)
       #     MAP_TO_QUERY_SLUMS=$(cat $MODULE/saved_query_settings | head -n5 | tail -n1)
       #     
       #     echo $MAP_TO_QUERY_POPULATION > $MODULE/saved_query_settings
       #     echo $COLUMN_POPULATION >> $MODULE/saved_query_settings
       #     echo $MAP_TO_QUERY_OWNERSHIP >> cat $MODULE/saved_query_settings
       #     echo $COLUMN_OWNERSHIP >> $MODULE/saved_query_settings
       #     echo $MAP_TO_QUERY_SLUMS >> $MODULE/saved_query_settings
       #     echo $QUERY_AREA_1 >> $MODULE/saved_query_settings
                
    # Listing maps (from PERMANENT mapset, with numeric column) When listed, user can be asked to select a map.
        rm -f $MODULE/temp_numeric_map
        touch $MODULE/temp_numeric_map
        for i in $(grass $GRASS/$MAPSET --exec g.list mapset=PERMANENT type=vector | grep -vE 'lines_osm|lines|points_osm|polygons_osm|polygons|relations_osm|relations|selection'); do        
            if [[ $(grass $GRASS/$MAPSET --exec  db.describe table=$i database=~/cityapp/grass/global/PERMANENT/sqlite/sqlite.db | grep -E 'DOUBLE\ PRECISION|INTEGER' | grep -vE 'CAT|cat') ]]
                then
                    echo $i >> $MODULE/temp_numeric_map
            fi
        done  
    
    if [ -e $MODULE/saved_query_settings ]
        then
            # Saved settings found. It contains a saved set of selections. Do you want to use that? 
                Send_Message m 4 module_2b.4 question [\"Yes\",\"No\"]
                    Request
                        USE_SAVED_SETTINGS=$REQUEST_CONTENT
                        case $USE_SAVED_SETTINGS in
                            "yes"|"Yes"|"YES")
                                INIT=0
                                MAP_TO_QUERY_POPULATION=$(cat $MODULE/saved_query_settings | head -n1)
                                COLUMN_POPULATION=$(cat $MODULE/saved_query_settings | head -n2 | tail -n1)
                                MAP_TO_QUERY_OWNERSHIP=$(cat $MODULE/saved_query_settings | head -n3 | tail -n1)
                                COLUMN_OWNERSHIP=$(cat $MODULE/saved_query_settings | head -n4 | tail -n1)
                                MAP_TO_QUERY_SLUMS=$(cat $MODULE/saved_query_settings | head -n5 | tail -n1)
                                ;;
                            "no"|"No"|"NO")
                                INIT=1
                                ;;
                        esac
        else
            INIT=1
    fi
    
    if [ $INIT -eq 1 ]
        then
            # Select a map for demographic data
                Send_Message l 5 module_2b.5 select actions [\"OK\"] $MODULE/temp_numeric_map
                    Request
                        MAP_TO_QUERY_POPULATION=$REQUEST_CONTENT
                        # copy for achiving
                        echo $MAP_TO_QUERY_POPULATION > $MODULE/temp_selected_population_map

                        # Now it is possible to chechk if the map to query is in the default mapset (set in the header as MAPSET), or not. If not, the map has to be copied into the module_2 mapset and the further processes will taken in this mapset.
                        
                        if [ grass $GRASS/$MAPSET --exec g.list type=vector mapset=module_2 | grep "$MAP_TO_QUERY_POPULATION" ]
                            then
                                INIT=$INIT
                            else
                                grass $GRASS/$MAPSET --exec g.copy vector=$MAP_TO_QUERY_POPULATION"@"PERMANENT,$MAP_TO_QUERY_POPULATION
                        fi
                        
            # Select demographic data column
            grass $GRASS/$MAPSET --exec db.describe -c table=$MAP_TO_QUERY_POPULATION | grep -E 'DOUBLE\ PRECISION|INTEGER' | grep -vE 'CAT|cat' | cut -d":" -f2 > $MODULE/temp_columns_population
                Send_Message l 6 module_2b.6 select actions [\"OK\"] $MODULE/temp_columns_population
                    Request
                        COLUMN_POPULATION=$REQUEST_CONTENT
                        # copy for achiving
                        echo $COLUMN_POPULATION > $MODULE/temp_selected_population_column 

            # Listing maps (from PERMANENT mapset, with any column)
                rm -f $MODULE/temp_generic_map
                touch $MODULE/temp_generic_map
                for i in $(grass $GRASS/$MAPSET --exec g.list mapset=PERMANENT type=vector | grep -vE 'lines_osm|lines|points_osm|polygons_osm|polygons|relations_osm|relations|selection'); do
                    echo $i >> $MODULE/temp_generic_map
                done    
            
            # Select a map for land ownership data
                Send_Message l 7 module_2b.7 select actions [\"OK\"] $MODULE/temp_generic_map
                    Request
                        MAP_TO_QUERY_OWNERSHIP=$REQUEST_CONTENT
                        # copy for achiving
                        echo $MAP_TO_QUERY_OWNERSHIP > $MODULE/temp_selected_ownership_map

                        # Now it is possible to chechk if the map to query is in the default mapset (set in the header as MAPSET), or not. If not, the map has to be copied into the module_2 mapset and the further processes will taken in this mapset.
                        
                        if [ grass $GRASS/$MAPSET --exec g.list type=vector mapset=module_2 | grep "$MAP_TO_QUERY_OWNERSHIP" ]
                            then
                                INIT=1
                            else
                                grass $GRASS/$MAPSET --exec g.copy vector=$MAP_TO_QUERY_OWNERSHIP"@"PERMANENT,$MAP_TO_QUERY_OWNERSHIP
                        fi
    
            # Select ownership data column
                grass $GRASS/$MAPSET --exec db.describe -c table=$MAP_TO_QUERY_OWNERSHIP | grep -vE 'CAT|cat' | cut -d":" -f2 > $MODULE/temp_ownership_column
                Send_Message l 8 module_2b.8 select actions [\"OK\"] $MODULE/temp_ownership_column
                    Request
                        COLUMN_OWNERSHIP=$REQUEST_CONTENT
                        # copy for achiving
                        echo $COLUMN_OWNERSHIP > $MODULE/temp_selected_ownership_column
                        
                        
            # Select a map, containing slum areas
                Send_Message l 9 module_2b.9 select actions [\"OK\"] $MODULE/temp_generic_map
                    Request
                        MAP_TO_QUERY_SLUMS=$REQUEST_CONTENT
                        # copy for achiving
                        echo $MAP_TO_QUERY_SLUMS > $MODULE/temp_selected_slums_map

                        # Now it is possible to chechk if the map to query is in the default mapset (set in the header as MAPSET), or not. If not, the map has to be copied into the module_2 mapset and the further processes will taken in this mapset.
                        
                        if [ grass $GRASS/$MAPSET --exec g.list type=vector mapset=module_2 | grep "$MAP_TO_QUERY_SLUMS" ]
                            then
                                INIT=1
                            else
                                grass $GRASS/$MAPSET --exec g.copy vector=$MAP_TO_QUERY_SLUMS"@"PERMANENT,$MAP_TO_QUERY_SLUMS
                        fi
                
            # Settings are automatically saved in a file
            # Do you want to save your selections (except the area selection) in a file? If yes, next time you can easily apply the same settings for an other area.
                #Send_Message m 10 module_2b.10 question actions [\"Yes\",\"No\"]
                #    Request
                #        SAVE_SELECTIONS=$REQUEST_CONTENT
                #        case $SAVE_SELECTIONS in
                #            "yes"|"Yes"|"YES")
                                rm -f $MODULE/saved_query_settings
                                
                                cat $MODULE/temp_selected_population_map > $MODULE/saved_query_settings
                                cat $MODULE/temp_selected_population_column >> $MODULE/saved_query_settings
                                cat $MODULE/temp_selected_ownership_map >> $MODULE/saved_query_settings
                                cat $MODULE/temp_selected_ownership_column >> $MODULE/saved_query_settings
                                cat $MODULE/temp_selected_slums_map >> $MODULE/saved_query_settings
                                echo $QUERY_AREA_1 >> $MODULE/saved_query_settings
                 #               ;;
                 #       esac
    fi
    
            
##############
#  Processing 
##############


    Process_Check start calculations
    
        grass $GRASS/$MAPSET --exec ~/cityapp/scripts/modules/module_2b/module_2b_query_process.sh
    
    Process_Check stop calculations
    
    
    # To process exit, click OK.
    Send_Message m 3 module_2b.3 question actions [\"OK\"]
        Request
            Running_Check stop
            Close_Process
exit
