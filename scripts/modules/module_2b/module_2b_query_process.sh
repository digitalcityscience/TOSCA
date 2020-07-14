#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.2
# CityApp module
# This module is to query any existing map by a user-defined area -- querying attribute data only
# 2020. július 8.
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

    MAP_TO_QUERY_POPULATION=$(cat $MODULE/saved_query_settings | head -n1)
    COLUMN_POPULATION=$(cat $MODULE/saved_query_settings | head -n2 | tail -n1)
    MAP_TO_QUERY_OWNERSHIP=$(cat $MODULE/saved_query_settings | head -n3 | tail -n1)
    COLUMN_OWNERSHIP=$(cat $MODULE/saved_query_settings | head -n4 | tail -n1)
  
  # Ezt a térképet még nem használjuk, de kelleni fog: ebből jön a slum-ok területe és száma a lekérdezési területen
    MAP_TO_QUERY_SLUMS=$(cat $MODULE/saved_query_settings | head -n5 | tail -n1)
    QUERY_AREA_1=$(cat $MODULE/saved_query_settings | head -n6 | tail -n1)
                        
        # Clipping maps by query area
        v.clip input=$MAP_TO_QUERY_POPULATION clip=$QUERY_AREA_1 output=clipped_population --overwrite
        v.clip input=$MAP_TO_QUERY_OWNERSHIP clip=$QUERY_AREA_1 output=clipped_land_ownership --overwrite # HIBA
        
        
        # Most megállapítjuk, hogy az egyes tulajdonosformákból mennyi van, és azok összesen mekkora kiterjedésűek, mennyi háztartás van rajuk és mekkora ezek  összes lakossága

        # Először a kormányzati területek
       
            v.extract input=clipped_land_ownership where="$COLUMN_OWNERSHIP='Govt Reserved' OR $COLUMN_OWNERSHIP='Govt Forest' OR $COLUMN_OWNERSHIP='Govt' OR $COLUMN_OWNERSHIP='Forest Department'" output=clipped_lands_governmental --overwrite --quiet
            
            # Numer of areas:
                NUMBER_OF_GOV_OWNED_LANDS=$(v.info -t map=clipped_lands_governmental | head -n6 | tail -n1 | cut -d"=" -f2)
            
            # A kormányzati tulajdonú területek összes kiterjedése (m2)
                AREA_OF_GOV_OWNED_LANDS=0;
                COLUMN=$(v.report map=clipped_lands_governmental option=area units=feet sort=asc | head -n1 | sed s''/[a-z,A-Z,0-9,_]//g | wc -c)
                i=0
                for i in $(v.report map=clipped_lands_governmental option=area units=meters sort=asc | cut -d"|" -f$COLUMN);do
                    AREA_OF_GOV_OWNED_LANDS=$(echo "$AREA_OF_GOV_OWNED_LANDS+$i" | bc);
                done
                
                AREA_OF_GOV_OWNED_LANDS=$(echo $AREA_OF_GOV_OWNED_LANDS | cut -d"." -f1)
            
            # Házak (háztartások) száma kormányzati területen
                v.clip input=clipped_population clip=clipped_lands_governmental output=population_on_governmental_land --overwrite
                NUMBER_OF_HOUSES_GOV_LANDS=$(v.info -t map=population_on_governmental_land | head -n6 | tail -n1 | cut -d"=" -f2)
                
            # Lakosok száma kormányzati területen
                POPULATION_ON_GOV_LANDS=$(v.db.univar -g map=population_on_governmental_land column=$COLUMN_POPULATION | grep sum | cut -d"=" -f2)

        # Aztán a magántulajdonú területek
            v.extract input=clipped_land_ownership where="$COLUMN_OWNERSHIP='Private'" output=clipped_lands_private --overwrite --quiet
            
            # Numer of areas:
                NUMBER_OF_PRIVATE_OWNED_LANDS=$(v.info -t map=clipped_lands_private | head -n6 | tail -n1 | cut -d"=" -f2)
            
            # A magán tulajdonú területek összes kiterjedése (m2)
                AREA_OF_PRIVATE_OWNED_LANDS=0;
                COLUMN=$(v.report map=clipped_lands_private option=area units=feet sort=asc | head -n1 | sed s''/[a-z,A-Z,0-9,_]//g | wc -c)
                i=0
                for i in $(v.report map=clipped_lands_private option=area units=meters sort=asc | cut -d"|" -f$COLUMN);do
                    AREA_OF_PRIVATE_OWNED_LANDS=$(echo "$AREA_OF_PRIVATE_OWNED_LANDS+$i" | bc);
                done

                AREA_OF_PRIVATE_OWNED_LANDS=$(echo $AREA_OF_PRIVATE_OWNED_LANDS | cut -d"." -f1)
            
            # Házak (háztartások) száma magán területen
                v.clip input=clipped_population clip=clipped_lands_private output=population_on_private_land --overwrite
                NUMBER_OF_HOUSES_PRIVATE_LANDS=$(v.info -t map=population_on_private_land | head -n6 | tail -n1 | cut -d"=" -f2)
                
            # Lakosok száma magán területen
                POPULATION_ON_PRIVATE_LANDS=$(v.db.univar -g map=population_on_private_land column=$COLUMN_POPULATION | grep sum | cut -d"=" -f2)
            
        # Templomi tulajdonok
            v.extract input=clipped_land_ownership where="$COLUMN_OWNERSHIP='Temple/Trustee'" output=clipped_lands_temple --overwrite --quiet
            
            # Numer of areas:
                NUMBER_OF_TEMPLE_OWNED_LANDS=$(v.info -t map=clipped_lands_temple | head -n6 | tail -n1 | cut -d"=" -f2)
            
            # A templomi tulajdonú területek összes kiterjedése (m2)
                AREA_OF_TEMPLE_OWNED_LANDS=0;
                COLUMN=$(v.report map=clipped_lands_temple option=area units=feet sort=asc | head -n1 | sed s''/[a-z,A-Z,0-9,_]//g | wc -c)
                i=0
                for i in $(v.report map=clipped_lands_temple option=area units=meters sort=asc | cut -d"|" -f$COLUMN);do
                    AREA_OF_TEMPLE_OWNED_LANDS=$(echo "$AREA_OF_TEMPLE_OWNED_LANDS+$i" | bc);
                done
                
                AREA_OF_TEMPLE_OWNED_LANDS=$(echo $AREA_OF_TEMPLE_OWNED_LANDS | cut -d"." -f1)
            
            # Házak (háztartások) száma templomi területen
                v.clip input=clipped_population clip=clipped_lands_temple output=population_on_temple_land --overwrite
                NUMBER_OF_HOUSES_TEMPLE_LANDS=$(v.info -t map=population_on_temple_land | head -n6 | tail -n1 | cut -d"=" -f2)
                
            # Lakosok száma templomi területen
                POPULATION_ON_TEMPLE_LANDS=$(v.db.univar -g map=population_on_temple_land column=$COLUMN_POPULATION | grep sum | cut -d"=" -f2)

        # Ismeretlen tulajdonúak
            v.extract -r input=clipped_land_ownership where="$COLUMN_OWNERSHIP='Govt Reserved' OR $COLUMN_OWNERSHIP='Govt Forest' OR $COLUMN_OWNERSHIP='Govt' OR $COLUMN_OWNERSHIP='Forest Department' OR $COLUMN_OWNERSHIP='Private' OR $COLUMN_OWNERSHIP='Temple/Trustee'" output=clipped_lands_no_owner_data --overwrite --quiet
        
            # Numer of areas:
                NUMBER_OF_UNKNOWN_OWNED_LANDS=$(v.info -t map=clipped_lands_no_owner_data | head -n6 | tail -n1 | cut -d"=" -f2)
            
            # Az Ismeretlen tulajdonú területek összes kiterjedése (m2)
                AREA_OF_UNKNOWN_OWNED_LANDS=0;
                COLUMN=$(v.report map=clipped_lands_no_owner_data option=area units=feet sort=asc | head -n1 | sed s''/[a-z,A-Z,0-9,_]//g | wc -c)
                
                i=0
                for i in $(v.report map=clipped_lands_no_owner_data option=area units=meters sort=asc | cut -d"|" -f$COLUMN);do
                    AREA_OF_UNKNOWN_OWNED_LANDS=$(echo "$AREA_OF_UNKNOWN_OWNED_LANDS+$i" | bc);
                done
                
                AREA_OF_UNKNOWN_OWNED_LANDS=$(echo $AREA_OF_UNKNOWN_OWNED_LANDS | cut -d"." -f1)
            
            # Házak (háztartások) száma templomi területen
                v.clip input=clipped_population clip=clipped_lands_no_owner_data output=population_on_unknown_owned_land --overwrite
                NUMBER_OF_HOUSES_UNKNOWN_OWNED_LANDS=$(v.info -t map=population_on_no_unknown_owned_land | head -n6 | tail -n1 | cut -d"=" -f2)
                
            # Lakosok száma templomi területen
                POPULATION_ON_UNKNOWN_OWNED_LANDS=$(v.db.univar -g map=population_on_unknown_owned_land column=$COLUMN_POPULATION | grep sum | cut -d"=" -f2)

            # String (text and numberic data) output 

        # Data output -- not only a text output, but there will a pdf output too
        # First: creating a text output, and inseting into a pdf file.
        
        rm -f $MODULE/temp_statistics_output_1
        touch $MODULE/temp_statistics_output_1
            
            echo "" > $MODULE/temp_statistics_output_1
            echo "GOVERNMET" >> $MODULE/temp_statistics_output_1
            echo "Governmental area (in square meters): $AREA_OF_GOV_OWNED_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Number of governmental areas: $NUMBER_OF_GOV_OWNED_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Number of households on governmental land: $NUMBER_OF_HOUSES_GOV_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Population on governmental land: $POPULATION_ON_GOV_LANDS" >> $MODULE/temp_statistics_output_1
            echo "" >> $MODULE/temp_statistics_output_1
            echo "PRIVATE" >> $MODULE/temp_statistics_output_1
            echo "Private area (in square meters): $AREA_OF_PRIVATE_OWNED_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Number of private areas: $NUMBER_OF_PRIVATE_OWNED_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Number of households on private land: $NUMBER_OF_HOUSES_PRIVATE_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Population on prvate land: $POPULATION_ON_PRIVATE_LANDS" >> $MODULE/temp_statistics_output_1
            echo "" >> $MODULE/temp_statistics_output_1
            echo "TEMPLE" >> $MODULE/temp_statistics_output_1
            echo "Temple owned area (in square meters): $AREA_OF_TEMPLE_OWNED_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Number of temple owned areas: $NUMBER_OF_TEMPLE_OWNED_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Number of households on temple land: $NUMBER_OF_HOUSES_TEMPLE_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Population on temple land: $POPULATION_ON_TEMPLE_LANDS" >> $MODULE/temp_statistics_output_1
            echo "" >> $MODULE/temp_statistics_output_1
            echo "UNKNOWN OWNER/NO DATA">> $MODULE/temp_statistics_output_1
            echo "Unknown owned area (in square meters): $AREA_OF_UNKNOWN_OWNED_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Number of unknown owned area: $NUMBER_OF_UNKNOWN_OWNED_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Number of households on unknown owned land: $NUMBER_OF_HOUSES_UNKNOWN_OWNED_LANDS" >> $MODULE/temp_statistics_output_1
            echo "Population on unknown owned land: $POPULATION_ON_UNKNOWN_OWNED_LANDS" >> $MODULE/temp_statistics_output_1
            echo "" >> $MODULE/temp_statistics_output_1
            echo "" >> $MODULE/temp_statistics_output_1
            echo "Map colors:" >> $MODULE/temp_statistics_output_1
            echo "Red: . . . . . . . . . . . . . Governmental owned lands" >> $MODULE/temp_statistics_output_1
            echo "Blue: . . . . . . . . . . . .  Private lands" >> $MODULE/temp_statistics_output_1
            echo "Yellow: . . . . . . . . . . .  Temple owned lands" >> $MODULE/temp_statistics_output_1
            echo "Grey: . . . . . . . . . . . .  Unknow owner or no data" >> $MODULE/temp_statistics_output_1 
            echo "Green with lightgrey fill: . . Query area" >> $MODULE/temp_statistics_output_1

            
            # Sending to frontend as 'info' file
            rm -f $MESSAGE_SENT/*.info
            cp $MODULE/temp_statistics_output_1 $MESSAGE_SENT/module_2b.1.info
        
            # Writing output to a pdf file
            cat $MODULE/temp_statistics_output_1 | sed s'/"//'g | sed s'/{//'g | sed s'/}//'g > $MODULE/temp_statistics_text_1
            enscript -p $MODULE/temp_statistics_1.ps $MODULE/temp_statistics_text_1
            ps2pdf $MODULE/temp_statistics_1.ps $MODULE/temp_statistics_1.pdf
            
        # Second: creating a multilayer map for pdf output. For this end has to use maps and an external style file
        
            ps.map input=$MODULE/ps_param_1 output=$MODULE/temp_query_map_1.ps --overwrite
            ps2pdf $MODULE/temp_query_map_1.ps $MODULE/temp_query_map_1.pdf

            gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=$MODULE/temp_query_results_$DATE_VALUE_2".pdf" $MODULE/temp_statistics_1.pdf $MODULE/temp_query_map_1.pdf
            
            mv $MODULE/temp_query_results_$DATE_VALUE_2".pdf" ~/cityapp/saved_results/query_results_$DATE_VALUE_2".pdf"
        exit
