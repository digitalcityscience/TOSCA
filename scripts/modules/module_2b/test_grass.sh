#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.31
# CityApp module
# This module is to query any existing map by a user-defined area -- querying attribute data only
# 2020. április 18.
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
        MAP_TO_QUERY_POPULATION=bbswr_slum_houses
        v.clip input=$MAP_TO_QUERY_POPULATION clip=$QUERY_AREA_1  output=clipped_population --overwrite
        
        # Most megállapítjuk, hogy az egyes tulajdonosformákból mennyi van, és azok összesen mekkora kiterjedésűek, mennyi háztartás van rajuk és mekkora ezek  összes lakossága

        # Először a kormányzati területek
       
            v.extract input=clipped_land_ownership where="Ownership='Govt Reserved' OR Ownership='Govt Forest' OR Ownership='Govt' OR Ownership='Forest Department'" output=clipped_lands_governmental --overwrite --quiet
            
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
                POPULATION_ON_GOV_LANDS=$(v.db.univar -g map=population_on_governmental_land column=total_family_members | grep sum | cut -d"=" -f2)

        # Aztán a magántulajdonú területek
            v.extract input=clipped_land_ownership where="Ownership='Private'" output=clipped_lands_private --overwrite --quiet
            
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
                POPULATION_ON_PRIVATE_LANDS=$(v.db.univar -g map=population_on_private_land column=total_family_members | grep sum | cut -d"=" -f2)
            
        # Templomi tulajdonok
            v.extract input=clipped_land_ownership where="Ownership='Temple/Trustee'" output=clipped_lands_temple --overwrite --quiet
            
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
                POPULATION_ON_TEMPLE_LANDS=$(v.db.univar -g map=population_on_temple_land column=total_family_members | grep sum | cut -d"=" -f2)

        # Ismeretlen tulajdonúak
            v.extract -r input=clipped_land_ownership where="Ownership='Govt Reserved' OR Ownership='Govt Forest' OR Ownership='Govt' OR Ownership='Forest Department' OR Ownership='Private' OR Ownership='Temple/Trustee'" output=clipped_lands_no_owner_data --overwrite --quiet
        
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
                POPULATION_ON_UNKNOWN_OWNED_LANDS=$(v.db.univar -g map=population_on_unknown_owned_land column=total_family_members | grep sum | cut -d"=" -f2)

            
            

            echo
            echo "Governmental area (in square meters): $AREA_OF_GOV_OWNED_LANDS"
            echo "Number of governmental areas: $NUMBER_OF_GOV_OWNED_LANDS"
            echo "Number of households on governmental land: $NUMBER_OF_HOUSES_GOV_LANDS"
            echo "Population on governmental land: $POPULATION_ON_GOV_LANDS"
            echo
            echo
            echo "Private area (in square meters): $AREA_OF_PRIVATE_OWNED_LANDS"
            echo "Number of private areas: $NUMBER_OF_PRIVATE_OWNED_LANDS"
            echo "Number of households on private land: $NUMBER_OF_HOUSES_PRIVATE_LANDS"
            echo "Population on prvate land: $POPULATION_ON_PRIVATE_LANDS"
            echo
            echo
            echo "Temple owned area (in square meters): $AREA_OF_TEMPLE_OWNED_LANDS"
            echo "Number of temple owned areas: $NUMBER_OF_TEMPLE_OWNED_LANDS"
            echo "Number of households on temple land: $NUMBER_OF_HOUSES_TEMPLE_LANDS"
            echo "Population on temple land: $POPULATION_ON_TEMPLE_LANDS"
            echo
            echo "Unknown owned area (in square meters): $AREA_OF_UNKNOWN_OWNED_LANDS"
            echo "Number of unknown owned area: $NUMBER_OF_UNKNOWN_OWNED_LANDS"
            echo "Number of households on unknown owned land: $NUMBER_OF_HOUSES_UNKNOWN_OWNED_LANDS"
            echo "Population on unknown owned land: $POPULATION_ON_UNKNOWN_OWNED_LANDS"
            echo
           
           
        exit
