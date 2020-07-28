#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.4
# CityApp module
# This module is a part of module_2b
# This module is to query lands by landowners, slum households (number of houses and population) by households tenure type.
# It is dedicated for Bhubaneshwar slums dataset
# 2020. július 26.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
#-- Initial settings -------------------
#

cd ~/cityapp

MODULES=~/cityapp/scripts/modules;
MODULE=~/cityapp/scripts/modules/module_2b;
MODULE_NAME=module_2b;
VARIABLES=~/cityapp/scripts/shared/variables;
BROWSER=~/cityapp/data_from_browser;
LANGUAGE=$(cat ~/cityapp/scripts/shared/variables/lang);
MESSAGE_TEXT=~/cityapp/scripts/shared/messages/$LANGUAGE/module_2b;
MESSAGE_SENT=~/cityapp/data_to_client;
GEOSERVER=~/cityapp/geoserver_data;
GRASS=~/cityapp/grass/global;
MAPSET=module_2;
DATE_VALUE=$(date +%Y-%m-%d" "%H":"%M);
DATE_VALUE_2=$(date +%Y_%m_%d_%H_%M);

QUERY_RESOLUTION=0.00002

Process_Check start calculations

    #First, setting the region to the entire calculation area
        g.region vector=selection@PERMANENT

    # Next, loading default map settings from "query_defaults" file
        MAP_TO_QUERY_HOUSEHOLDS=$(cat $MODULE/query_defaults | head -n1)
        COLUMN_POPULATION=$(cat $MODULE/query_defaults | head -n2 | tail -n1)
        COLUMN_HOUSE_STATUS=$(cat $MODULE/query_defaults | head -n3 | tail -n1)
        MAP_TO_QUERY_OWNERSHIP=$(cat $MODULE/query_defaults | head -n4 | tail -n1)
        COL_OWNER=$(cat $MODULE/query_defaults | head -n5 | tail -n1);
        MAP_TO_QUERY_SLUMS=$(cat $MODULE/query_defaults | head -n5 | tail -n1);
        QUERY_AREA_1=$(cat $MODULE/query_defaults | head -n7 | tail -n1)

    # If any of basemaps are missing, importing 
        if [ ! $(g.list type=vector | grep $MAP_TO_QUERY_HOUSEHOLDS | grep -v grep) ]
            then
                v.import input=~/cityapp/geoserver_data/bhubaneshwar/bbswr_slum_houses_ownership.gpkg output=bbswr_slum_houses_ownership --overwrite
        fi

        if [ ! $(g.list type=vector | grep $MAP_TO_QUERY_OWNERSHIP | grep -v grep) ]
            then
                v.import input=~/cityapp/geoserver_data/bhubaneshwar/land_owners.gpkg output=land_owners --overwrite
        fi
   
    # Knowing the query area, now it is the time to clip base maps by query area
    # From this point resultant (clipped) maps will only be used.
        v.select ainput=$MAP_TO_QUERY_OWNERSHIP atype=point,line,boundary,centroid,area binput=$QUERY_AREA_1 output=clipped_lands operator=overlap --overwrite     
        v.select ainput=$MAP_TO_QUERY_HOUSEHOLDS atype=point,line,boundary,centroid,area binput=$QUERY_AREA_1 output=clipped_households operator=overlap --overwrite

        # For later calculations, adding a new colum to the clipped_land map.
            v.db.addcolumn map=clipped_lands columns="area DOUBLE"
        
        # Uploading area of the separate land features into the new column
            v.to.db map=clipped_lands option=area columns=area units=meters

    # Setting calculation region to query_area_1
        g.region vector=query_area_1
    
    # Converting clipped_households maps into a pont map (centroids are converted into point)
        v.type input=clipped_households output=clipped_households_points from_type=centroid to_type=point --overwrite

    # Adding a new datacolumn to  the point map, to store the new ownersip data
        v.db.addcolumn map=clipped_households_points columns="owner_set VARCHAR(50)"
    
    # Reading land ownersip values from clipped_lands and writing them into the new column
        v.what.vect map=clipped_households_points column=owner_set query_map=clipped_lands query_column=$COL_OWNER

    # Now this new point map is ready for complex a query
        
        # First the total population, amount of houses, land area and number of lands
        # Total population, amount of houses, land area and number of lands on query area
            
            unset TABLE_DATA
            rm -f $MODULE/temp_outfile.csv
            touch $MODULE/temp_outfile.csv
            
            HOUSE_TOT=$(v.db.univar map=clipped_households_points column=total_family_members | head -n1 | cut -d":" -f2 | sed s'/ //'g )
            POP_TOT=$(v.db.univar map=clipped_households_points column=total_family_members | tail -n1 | cut -d":" -f2 | sed s'/ //'g )
            LAND_TOT=$(v.db.univar map=clipped_lands column=area | head -n1 | cut -d":" -f2 | sed s'/ //'g)
            AREA_TOT=$(v.db.univar map=clipped_lands column=area | tail -n1 | cut -d":" -f2 | sed s'/ //'g | cut -d"." -f1 | cut -d',' -f1)
            
            TABLE_DATA="Total summed result,,$LAND_TOT,,,$AREA_TOT,,,$HOUSE_TOT,,,$POP_TOT,,,"            
            echo $TABLE_DATA >> $MODULE/temp_outfile.csv
            
            for i in $(cat $MODULE/land_owner_values);do
                unset TABLE_DATA
                
                ID_LAND=$(echo $i | cut -d":" -f1 | sed s'/-/ /'g)
                VALUE_L=$(echo $i | cut -d":" -f2 | sed s'/-/ /'g)
                OUT_FILENAME=$(echo $i | cut -d":" -f3)
                                
                LAND_SUM=$(v.db.univar map=clipped_lands column=area where="$VALUE_L" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                    if [[ $LAND_SUM -eq 0 ]] || [[ ! $LAND_SUM ]]
                        then
                            LAND_SUM=0
                            AREA_SUM=0
                            HOUSE_SUM=0
                            POP_SUM=0
                        else
                            LAND_SUM_PERCENT_OF_TOT=$(echo "($LAND_SUM/$LAND_TOT)*100"| calc -dp | cut -c 1-4)
                            AREA_SUM=$(v.db.univar map=clipped_lands column=area where="$VALUE_L" | tail -n1 | cut -d":" -f2 | sed s'/ //'g | cut -d"." -f1 | cut -d"," -f1)
                            AREA_SUM_PERCENT_OF_TOT=$(echo "($AREA_SUM/$AREA_TOT)*100"| calc -dp | cut -c 1-4)
                            HOUSE_SUM=$(v.db.univar map=clipped_households_points column=total_family_members where="$VALUE_L" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                            HOUSE_SUM_PERCENT_OF_TOT=$(echo "($HOUSE_SUM/$HOUSE_TOT)*100"| calc -dp | cut -c 1-4)
                            POP_SUM=$(v.db.univar map=clipped_households_points column=total_family_members where="$VALUE_L" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                            POP_SUM_PERCENT_OF_TOT=$(echo "($POP_SUM/$POP_TOT)*100"| calc -dp | cut -c 1-4)
                            
                            TABLE_DATA="$ID_LAND,,$LAND_SUM,100,$LAND_SUM_PERCENT_OF_TOT,$AREA_SUM,100,$AREA_SUM_PERCENT_OF_TOT,$HOUSE_SUM,100,$HOUSE_SUM_PERCENT_OF_TOT,$POP_SUM,100,$POP_SUM_PERCENT_OF_TOT"
                            echo $TABLE_DATA >> $MODULE/temp_outfile.csv
                            
                            HOUSES=0
                            POPS=0
                            for i in $(cat $MODULE/house_owner_values);do
                                
                                unset TABLE_DATA
                                
                                ID_TENURE=$(echo $i | cut -d":" -f1 | sed s'/-/ /'g)
                                VALUE_H=$(echo $i | cut -d":" -f2 | sed s'/-/ /'g)
                                COMP_VALUE="$VALUE_H "AND" $VALUE_L"
                                HOUSE=$(v.db.univar map=clipped_households_points column=total_family_members where="$COMP_VALUE" | head -n1 | cut -d":" -f2 | sed s'/ //'g )
                                HOUSE_SUM_PERCENT=$(echo "($HOUSE/$HOUSE_SUM)*100"| calc -dp | cut -c 1-4)
                                HOUSE_TOT_PERCENT=$(echo "($HOUSE/$HOUSE_TOT)*100"| calc -dp | cut -c 1-4)
                                POP=$(v.db.univar map=clipped_households_points column=total_family_members where="$COMP_VALUE" | tail -n1 | cut -d":" -f2 | sed s'/ //'g )
                                POP_SUM_PERCENT=$(echo "($POP/$POP_SUM)*100"| calc -dp | cut -c 1-4)
                                POP_TOT_PERCENT=$(echo "($POP/$POP_TOT)*100"| calc -dp | cut -c 1-4)
                                
                                HOUSES=$(($HOUSE+$HOUSES))
                                POPS=$(($POP+$POPS))

                                TABLE_DATA=",$ID_TENURE,,,,,,,$HOUSE,$HOUSE_SUM_PERCENT,$HOUSE_TOT_PERCENT,$POP,$POP_SUM_PERCENT,$POP_TOT_PERCENT"
                                echo $TABLE_DATA >> $MODULE/temp_outfile.csv
                                unset TABLE_DATA
                            done
                            
                            HOUSE_REM=$(($HOUSE_SUM-$HOUSES))
                            HOUSE_REM_SUM_PERCENT=$(echo "($HOUSE_REM/$HOUSE_SUM)*100"| calc -dp | cut -c 1-4)
                            HOUSE_REM_TOT_PERCENT=$(echo "($HOUSE_REM/$HOUSE_TOT)*100"| calc -dp | cut -c 1-4)
                            
                            POP_REM=$(($POP_SUM-$POPS))
                            POP_REM_SUM_PERCENT=$(echo "($POP_REM/$POP_REM_SUM)*100"| calc -dp | cut -c 1-4)
                            POP_REM_TOT_PERCENT=$(echo "($POP_REM/$POP_REM_TOT)*100"| calc -dp | cut -c 1-4)
                            
                            TABLE_DATA=",$ID_TENURE,,,,,,,$HOUSE_REM,$HOUSE_REM_SUM_PERCENT,$HOUSE_REM_TOT_PERCENT,$POP_REM,$POP_REM_SUM_PERCENT,$POP_REM_TOT_PERCENT"
                            echo $TABLE_DATA >> $MODULE/temp_outfile.csv
                            #finally, a vector output for the pdf output file
                            v.extract -t input=clipped_lands where="$VALUE_L" output=$OUT_FILENAME --overwrite 
                    fi
            done            
            

    # Creating a multilayer map for pdf output. For this end has to use maps and an external style file
        # Setting region to the entire selection, allowing to export the entire selected area as a ps map
            g.region vector=selection@PERMANENT
            
            ps.map input=$MODULE/ps_param_1 output=$MODULE/temp_query_map_1.ps --overwrite
            ps2pdf $MODULE/temp_query_map_1.ps $MODULE/temp_query_map_1.pdf

        # Setting region to the query area, allowing to export only the query area as a ps map
            g.region vector=query_area_1

            ps.map input=$MODULE/ps_param_2 output=$MODULE/temp_query_map_2.ps --overwrite
            ps2pdf $MODULE/temp_query_map_2.ps $MODULE/temp_query_map_2.pdf
    
        # Merging pdf maps into a single pdf file
            gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=$MODULE/temp_map_2.pdf $MODULE/temp_query_map_1.pdf $MODULE/temp_query_map_2.pdf
    
    
Process_Check stop calculations
exit
