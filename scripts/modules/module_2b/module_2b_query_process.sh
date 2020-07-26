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
            rm -f $MODULE/temp_dataoutput_1
            touch $MODULE/temp_dataoutput_1
            
            TOT_HOUSE=$(v.db.univar map=clipped_households_points column=total_family_members | head -n1 | cut -d":" -f2 | sed s'/ //'g )
            TOT_POP=$(v.db.univar map=clipped_households_points column=total_family_members | tail -n1 | cut -d":" -f2 | sed s'/ //'g )
            TOT_LAND=$(v.db.univar map=clipped_lands column=area | head -n1 | cut -d":" -f2 | sed s'/ //'g)
            TOT_AREA=$(v.db.univar map=clipped_lands column=area | tail -n1 | cut -d":" -f2 | sed s'/ //'g | cut -d"." -f1 | cut -d',' -f1)
            
            echo "Total amount of lands on query area: $TOT_LAND" >> $MODULE/temp_dataoutput_1
            echo "Total surface of query area (m2): $TOT_AREA" >> $MODULE/temp_dataoutput_1
            echo "Total amount of houses on query area: $TOT_HOUSE" >> $MODULE/temp_dataoutput_1
            echo "Total population on query area: $TOT_POP" >> $MODULE/temp_dataoutput_1
            echo >> $MODULE/temp_dataoutput_1
            
            for i in $(cat $MODULE/land_owner_values);do
                ID=$(echo $i | cut -d":" -f1 | sed s'/-/ /'g)
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
                            AREA_SUM=$(v.db.univar map=clipped_lands column=area where="$VALUE_L" | tail -n1 | cut -d":" -f2 | sed s'/ //'g | cut -d"." -f1 | cut -d"," -f1)
                            HOUSE_SUM=$(v.db.univar map=clipped_households_points column=total_family_members where="$VALUE_L" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                            POP_SUM=$(v.db.univar map=clipped_households_points column=total_family_members where="$VALUE_L" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                            
                            echo "-----------------------------------------">> $MODULE/temp_dataoutput_1
                            echo >> $MODULE/temp_dataoutput_1
                            echo "$ID" >> $MODULE/temp_dataoutput_1
                            echo >> $MODULE/temp_dataoutput_1
                            echo "   Sum number of lands: $LAND_SUM" >> $MODULE/temp_dataoutput_1
                            echo "   Sum land area (m2): $AREA_SUM" >> $MODULE/temp_dataoutput_1
                            echo "   Sum number of houses: $HOUSE_SUM" >> $MODULE/temp_dataoutput_1
                            echo "   Sum population: $POP_SUM" >> $MODULE/temp_dataoutput_1
                            echo >> $MODULE/temp_dataoutput_1

                            HOUSES=0
                            POPS=0
                            for i in $(cat $MODULE/house_owner_values);do
                                ID=$(echo $i | cut -d":" -f1 | sed s'/-/ /'g)
                                VALUE_H=$(echo $i | cut -d":" -f2 | sed s'/-/ /'g)
                                COMP_VALUE="$VALUE_H "AND" $VALUE_L"
                                HOUSE=$(v.db.univar map=clipped_households_points column=total_family_members where="$COMP_VALUE" | head -n1 | cut -d":" -f2 | sed s'/ //'g )
                                POP=$(v.db.univar map=clipped_households_points column=total_family_members where="$COMP_VALUE" | tail -n1 | cut -d":" -f2 | sed s'/ //'g )
                                
                                HOUSES=$(($HOUSE+$HOUSES))
                                POPS=$(($POP+$POPS))
                                
                                echo "   $ID" >> $MODULE/temp_dataoutput_1
                                echo "      Houses: $HOUSE" >> $MODULE/temp_dataoutput_1
                                echo "      Population: $POP" >> $MODULE/temp_dataoutput_1
                            done
                            
                            HOUSE_REM=$(($HOUSE_SUM-$HOUSES))
                            POP_REM=$(($POP_SUM-$POPS))
                            echo >> $MODULE/temp_dataoutput_1
                            echo "   Houses without identifyable tenure status: $HOUSE_REM" >> $MODULE/temp_dataoutput_1
                            echo "   Total population of these houses: $POP_REM" >> $MODULE/temp_dataoutput_1
                            
                            #finally, a vector output for the pdf output file
                            v.extract -t input=clipped_lands where="$VALUE_L" output=$OUT_FILENAME --overwrite 

                    fi
            done

    # Converting output text into a ps, then convert into a pdf file
        enscript -p $MODULE/temp_statistics_1.ps $MODULE/temp_dataoutput_1
        ps2pdf $MODULE/temp_statistics_1.ps $MODULE/temp_statistics_1.pdf
        
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
    
    # Merging numeric output pdf and maps pdf into a single pdf file
        gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=$MODULE/temp_results_$DATE_VALUE_2".pdf" $MODULE/temp_statistics_1.pdf $MODULE/temp_map_2.pdf
        
        cp $MODULE/temp_results_$DATE_VALUE_2".pdf" $MESSAGE_SENT/info.pdf
        cp $MODULE/temp_results_$DATE_VALUE_2".pdf" ~/cityapp/saved_results/$MODULE/temp_results_$DATE_VALUE_2".pdf"
    
    Process_Check stop calculations
exit
