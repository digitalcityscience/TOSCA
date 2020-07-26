#! /bin/bash
. ~/cityapp/scripts/shared/functions.sh

# version 1.3
# CityApp module
# This module is to query any existing map by a user-defined area -- querying attribute data only
# 2020. július 23.
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


clear
echo
echo
echo "I am"
echo
echo


    g.region vector=selection@PERMANENT

    MAP_TO_QUERY_HOUSEHOLDS=$(cat $MODULE/query_defaults | head -n1)
    COLUMN_POPULATION=$(cat $MODULE/query_defaults | head -n2 | tail -n1)
    COLUMN_HOUSE_STATUS=$(cat $MODULE/query_defaults | head -n3 | tail -n1)
    MAP_TO_QUERY_OWNERSHIP=$(cat $MODULE/query_defaults | head -n4 | tail -n1)
    COLUMN_OWNERSHIP=$(cat $MODULE/query_defaults | head -n5 | tail -n1);
  
    if [ $(g.list type=vector | grep $MAP_TO_QUERY_HOUSEHOLDS | grep -v grep) ]
        then
            INIT=0
        else
            v.import input=~/cityapp/geoserver_data/bhubaneshwar/slum_households.gpkg output=slum_population --overwrite
    fi
  
    if [ $(g.list type=vector | grep $MAP_TO_QUERY_OWNERSHIP | grep -v grep) ]
        then
            INIT=0
        else
            v.import input=~/cityapp/geoserver_data/bhubaneshwar/land_owners.gpkg output=land_owners --overwrite
    fi
    
  # Ezt a térképet még nem használjuk, de kelleni fog: ebből jön a slum-ok területe és száma a lekérdezési területen
    MAP_TO_QUERY_SLUMS=$(cat $MODULE/query_defaults | head -n5 | tail -n1);
    QUERY_AREA_1=$(cat $MODULE/query_defaults | head -n7 | tail -n1)

# Clipping base maps

        # Clipping maps by query area
        v.clip input=$MAP_TO_QUERY_HOUSEHOLDS clip=$QUERY_AREA_1 output=clipped_households --overwrite
        v.clip input=$MAP_TO_QUERY_OWNERSHIP clip=$QUERY_AREA_1 output=clipped_lands --overwrite
        
################################
# Calculations by land ownersip
################################
 
        # Most megállapítjuk, hogy az egyes tulajdonosformákból mennyi van, és azok összesen mekkora kiterjedésűek, mennyi háztartás van rajuk és mekkora ezek  összes lakossága
        
        g.region vector=query_area_1
# ----------------------
# Government owned lands
       
        # Total number of government owned areas:
        v.extract input=clipped_lands where="$COLUMN_OWNERSHIP='Govt Reserved' OR $COLUMN_OWNERSHIP='Govt Forest' OR $COLUMN_OWNERSHIP='Govt' OR $COLUMN_OWNERSHIP='Forest Department'" output=clipped_lands_governmental --overwrite --quiet
            
            SUM_NUMBER_GOV_LANDS=$(v.db.univar -g map=clipped_lands_governmental column=cat | head -n1 | tail -n1 | cut -d"=" -f2)
            
            # Total area of government owned lands (m2)
            SUM_AREA_OF_GOV_OWNED_LANDS=0
            COLUMN=$(v.report map=clipped_lands_governmental option=area units=meters sort=asc | head -n1 | sed s''/[a-z,A-Z,0-9,_]//g | wc -c)
            for i in $(v.report map=clipped_lands_governmental option=area units=meters sort=asc | cut -d"|" -f$COLUMN);do
                SUM_AREA_OF_GOV_OWNED_LANDS=$(echo "scale=2;$i+$SUM_AREA_OF_GOV_OWNED_LANDS" | bc)
            done
            SUM_AREA_OF_GOV_OWNED_LANDS=$(echo $SUM_AREA_OF_GOV_OWNED_LANDS | cut -d"." -f1)
            
            # Calculating number of households and habitants on GOVERNMENT owned area by the legal status of the house
                v.clip input=clipped_households clip=clipped_lands_governmental output=households_on_governmental_land --overwrite
                CLIPPED_MAP=households_on_governmental_land
                
                    SUM_GOV_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members | head -n1 |  cut -d":" -f2 | sed s'/ //'g)
                    SUM_GOV_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                
                    GOV_LAND_PATTA_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Patta'" | head -n1 |  cut -d":" -f2 | sed s'/ //'g)
                        if [[ $GOV_LAND_PATTA_HOUSES -lt 1 ]] || [[ ! $GOV_LAND_PATTA_HOUSES ]]
                            then
                                GOV_LAND_PATTA_HOUSES=0
                                GOV_LAND_PATTA_POPULATION=0
                            else
                                GOV_LAND_PATTA_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Patta'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    GOV_LAND_OTHERS_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='others'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $GOV_LAND_OTHERS_HOUSES -lt 1 ]] || [[ ! $GOV_LAND_OTHERS_HOUSES ]]
                            then
                                GOV_LAND_OTHERS_HOUSES=0
                                GOV_LAND_OTHERS_POPULATION=0
                            else
                                GOV_LAND_OTHERS_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='others'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                    
                    GOV_LAND_POSSESSION_CERTIFICATE_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Possession Certificate/Occupancy Right'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $GOV_LAND_POSSESSION_CERTIFICATE_HOUSES -lt 1 ]] || [[ ! $GOV_LAND_POSSESSION_CERTIFICATE_HOUSES ]]
                            then
                                GOV_LAND_POSSESSION_CERTIFICATE_HOUSES=0
                                GOV_LAND_POSSESSION_CERTIFICATE_POPULATION=0
                            else
                                GOV_LAND_POSSESSION_CERTIFICATE_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Possession Certificate/Occupancy Right'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    GOV_LAND_PRIVATE_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Private Land Encroached'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $GOV_LAND_PRIVATE_LAND_HOUSES -lt 1 ]] || [[ ! $GOV_LAND_PRIVATE_LAND_HOUSES ]]
                            then
                                GOV_LAND_PRIVATE_LAND_HOUSES=0
                                GOV_LAND_PRIVATE_LAND_POPULATION=0
                            else
                                GOV_LAND_PRIVATE_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Private Land Encroached'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    GOV_LAND_PUBLIC_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Public Land Encroached'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $GOV_LAND_PUBLIC_LAND_HOUSES -lt 0 ]] || [[ ! $GOV_LAND_PUBLIC_LAND_HOUSES ]]
                            then
                                GOV_LAND_PUBLIC_LAND_HOUSES=0
                                GOV_LAND_PUBLIC_LAND_POPULATION=0
                            else
                                GOV_LAND_PUBLIC_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Public Land Encroached'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    GOV_LAND_RENTED_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Rented'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $GOV_LAND_RENTED_HOUSES -lt 1 ]] || [[ ! $GOV_LAND_RENTED_HOUSES ]]
                            then
                                GOV_LAND_RENTED_HOUSES=0
                                GOV_LAND_RENTED_POPULATION=0
                            else
                                GOV_LAND_RENTED_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Rented'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                    
                    GOV_LAND_NO_TENURESTATUS_HOUSES=$(($SUM_GOV_LAND_HOUSES-$GOV_LAND_PATTA_HOUSES-$GOV_LAND_OTHERS_HOUSES-$GOV_LAND_POSSESSION_CERTIFICATE_HOUSES-$GOV_LAND_PRIVATE_LAND_HOUSES-$GOV_LAND_PUBLIC_LAND_HOUSES-$GOV_LAND_RENTED_HOUSES))
                        if [[ $GOV_LAND_NO_TENURESTATUS_HOUSES -lt 1 ]] || [[ ! $GOV_LAND_NO_TENURESTATUS_HOUSES ]]
                            then
                                GOV_LAND_NO_TENURESTATUS_HOUSES=0
                                GOV_LAND_NO_TENURESTATUS_POPULATION=0
                            else
                                GOV_LAND_NO_TENURESTATUS_POPULATION=$(($SUM_GOV_LAND_POPULATION-$GOV_LAND_PATTA_POPULATION-$GOV_LAND_OTHERS_POPULATION-$GOV_LAND_POSSESSION_CERTIFICATE_POPULATION-$GOV_LAND_PRIVATE_LAND_POPULATION-$GOV_LAND_PUBLIC_LAND_POPULATION-$GOV_LAND_RENTED_POPULATION))
                        fi
# PRIVATE owned lands

        # Total number of private owned areas:
        v.extract input=clipped_lands where="$COLUMN_OWNERSHIP='Private' OR $COLUMN_OWNERSHIP='Govt Forest' OR $COLUMN_OWNERSHIP='Private Forest'" output=clipped_lands_private --overwrite --quiet
            
            SUM_NUMBER_PRIVATE_LANDS=$(v.db.univar -g map=clipped_lands_private column=cat | head -n1 | tail -n1 | cut -d"=" -f2)
            
            # Total area of private owned lands (m2)
            SUM_AREA_OF_PRIVATE_OWNED_LANDS=0
            COLUMN=$(v.report map=clipped_lands_private option=area units=meters sort=asc | head -n1 | sed s''/[a-z,A-Z,0-9,_]//g | wc -c)
            for i in $(v.report map=clipped_lands_private option=area units=meters sort=asc | cut -d"|" -f$COLUMN);do
                SUM_AREA_OF_PRIVATE_OWNED_LANDS=$(echo "scale=2;$i+$SUM_AREA_OF_PRIVATE_OWNED_LANDS" | bc)
            done
            SUM_AREA_OF_PRIVATE_OWNED_LANDS=$(echo $SUM_AREA_OF_PRIVATE_OWNED_LANDS | cut -d"." -f1)
            
                    
            # Calculating number of households and habitants on PRIVATE owned area by the legal status of the house
                v.clip input=clipped_households clip=clipped_lands_private output=households_on_private_land --overwrite
                CLIPPED_MAP=households_on_private_land
                
                    SUM_PRIVATE_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members | head -n1 |  cut -d":" -f2 | sed s'/ //'g)
                    SUM_PRIVATE_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                    
                    PRIVATE_LAND_PATTA_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Patta'" | head -n1 |  cut -d":" -f2 | sed s'/ //'g)
                        if [[ $PRIVATE_LAND_PATTA_HOUSES -lt 1 ]] || [[ ! $PRIVATE_LAND_PATTA_HOUSES ]]
                            then
                                PRIVATE_LAND_PATTA_HOUSES=0
                                PRIVATE_LAND_PATTA_POPULATION=0
                            else
                                PRIVATE_LAND_PATTA_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Patta'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                    
                    PRIVATE_LAND_OTHERS_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='others'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $PRIVATE_LAND_OTHERS_HOUSES -lt 1 ]] || [[ ! $PRIVATE_LAND_OTHERS_HOUSES ]]
                            then
                                PRIVATE_LAND_OTHERS_HOUSES=0
                                PRIVATE_LAND_OTHERS_POPULATION=0
                            else
                                PRIVATE_LAND_OTHERS_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='others'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Possession Certificate/Occupancy Right'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES -lt 1 ]] || [[ ! $PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES ]]
                            then
                                PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES=0
                                PRIVATE_LAND_POSSESSION_CERTIFICATE_POPULATION=0
                            else
                                PRIVATE_LAND_POSSESSION_CERTIFICATE_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Possession Certificate/Occupancy Right'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    PRIVATE_LAND_PRIVATE_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Private Land Encroached'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $PRIVATE_LAND_PRIVATE_LAND_HOUSES -lt 1 ]] || [[ ! $PRIVATE_LAND_PRIVATE_LAND_HOUSES ]]
                            then
                                PRIVATE_LAND_PRIVATE_LAND_HOUSES=0
                                PRIVATE_LAND_PRIVATE_LAND_POPULATION=0
                            else
                                PRIVATE_LAND_PRIVATE_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Private Land Encroached'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    PRIVATE_LAND_PUBLIC_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Public Land Encroached'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $PRIVATE_LAND_PUBLIC_LAND_HOUSES -lt 1 ]] || [[ ! $PRIVATE_LAND_PUBLIC_LAND_HOUSES ]]
                            then 
                                PRIVATE_LAND_PUBLIC_LAND_HOUSES=0
                                PRIVATE_LAND_PUBLIC_LAND_POPULATION=0
                            else
                                PRIVATE_LAND_PUBLIC_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Public Land Encroached'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    PRIVATE_LAND_RENTED_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Rented'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $PRIVATE_LAND_RENTED_HOUSES -lt 0 ]] || [[ ! $PRIVATE_LAND_RENTED_HOUSES ]]
                            then
                                PRIVATE_LAND_RENTED_HOUSES=0
                                PRIVATE_LAND_RENTED_POPULATION=0
                            else
                                PRIVATE_LAND_RENTED_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Rented'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                    PRIVATE_LAND_NO_TENURESTATUS_HOUSES=$(($SUM_PRIVATE_LAND_HOUSES-$PRIVATE_LAND_PATTA_HOUSES-$PRIVATE_LAND_OTHERS_HOUSES-$PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES-$PRIVATE_LAND_PRIVATE_LAND_HOUSES-$PRIVATE_LAND_PUBLIC_LAND_HOUSES-$PRIVATE_LAND_RENTED_HOUSES))
                        if [[ $PRIVATE_LAND_NO_TENURESTATUS_HOUSES -lt 1 ]] || [[ ! $PRIVATE_LAND_NO_TENURESTATUS_HOUSES ]]
                            then
                                PRIVATE_LAND_NO_TENURESTATUS_HOUSES=0
                                PRIVATE_LAND_NO_TENURESTATUS_POPULATION=0
                            else
                                PRIVATE_LAND_NO_TENURESTATUS_POPULATION=$(($SUM_PRIVATE_LAND_POPULATION-$PRIVATE_LAND_PATTA_POPULATION-$PRIVATE_LAND_OTHERS_POPULATION-$PRIVATE_LAND_POSSESSION_CERTIFICATE_POPULATION-$PRIVATE_LAND_PRIVATE_LAND_POPULATION-$PRIVATE_LAND_PUBLIC_LAND_POPULATION-$PRIVATE_LAND_RENTED_POPULATION))
                        fi
                        
# Temple/Trustee owned lands
       
        # Total number of temple/trustee owned areas:
        v.extract input=clipped_lands where="$COLUMN_OWNERSHIP='Temple/Trustee'" output=clipped_lands_temple --overwrite --quiet
            
            SUM_NUMBER_TEMPLE_LANDS=$(v.db.univar -g map=clipped_lands_temple column=cat | head -n1 | tail -n1 | cut -d"=" -f2)
            
            # Total area of temple/trustee owned lands (m2)
            SUM_AREA_OF_TEMPLE_OWNED_LANDS=0
            COLUMN=$(v.report map=clipped_lands_temple option=area units=meters sort=asc | head -n1 | sed s''/[a-z,A-Z,0-9,_]//g | wc -c)
            for i in $(v.report map=clipped_lands_temple option=area units=meters sort=asc | cut -d"|" -f$COLUMN);do
                SUM_AREA_OF_TEMPLE_OWNED_LANDS=$(echo "scale=2;$i+$SUM_AREA_OF_TEMPLE_OWNED_LANDS" | bc)
            done
            SUM_AREA_OF_TEMPLE_OWNED_LANDS=$(echo $SUM_AREA_OF_TEMPLE_OWNED_LANDS | cut -d"." -f1)
            
                    
            # Calculating number of households and habitants on PRIVATE owned area by the legal status of the house
                v.clip input=clipped_households clip=clipped_lands_temple output=households_on_temple_land --overwrite
                CLIPPED_MAP=households_on_temple_land
                
                    SUM_TEMPLE_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members | head -n1 |  cut -d":" -f2 | sed s'/ //'g)
                    SUM_TEMPLE_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                    
                    TEMPLE_LAND_PATTA_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Patta'" | head -n1 |  cut -d":" -f2 | sed s'/ //'g)
                        if [[ $TEMPLE_LAND_PATTA_HOUSES -lt 1 ]] || [[ ! $TEMPLE_LAND_PATTA_HOUSES ]]
                            then
                                TEMPLE_LAND_PATTA_HOUSES=0
                                TEMPLE_LAND_PATTA_POPULATION=0
                            else
                                TEMPLE_LAND_PATTA_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Patta'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                 
                    TEMPLE_LAND_OTHERS_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='others'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $TEMPLE_LAND_OTHERS_HOUSES -lt 1 ]] || [[ ! $TEMPLE_LAND_OTHERS_HOUSES ]]
                            then
                                TEMPLE_LAND_OTHERS_HOUSES=0
                                TEMPLE_LAND_OTHERS_POPULATION=0
                            else
                                TEMPLE_LAND_OTHERS_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='others'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                    
                    TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Possession Certificate/Occupancy Right'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES -lt 1 ]] || [[ ! $TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES ]]
                            then
                                TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES=0
                                TEMPLE_LAND_POSSESSION_CERTIFICATE_POPULATION=0
                            else
                                TEMPLE_LAND_POSSESSION_CERTIFICATE_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Possession Certificate/Occupancy Right'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                    
                    TEMPLE_LAND_PRIVATE_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Private Land Encroached'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $TEMPLE_LAND_PRIVATE_LAND_HOUSES -lt 1 ]] || [[ ! $TEMPLE_LAND_PRIVATE_LAND_HOUSES ]]
                            then
                                TEMPLE_LAND_PRIVATE_LAND_HOUSES=0
                                TEMPLE_LAND_PRIVATE_LAND_POPULATION=0
                            else
                                TEMPLE_LAND_PRIVATE_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Private Land Encroached'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                    
                    TEMPLE_LAND_PUBLIC_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Public Land Encroached'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $TEMPLE_LAND_PUBLIC_LAND_HOUSES -lt 1 ]] || [[ ! $TEMPLE_LAND_PUBLIC_LAND_HOUSES ]]
                            then
                                TEMPLE_LAND_PUBLIC_LAND_HOUSES=0
                                TEMPLE_LAND_PUBLIC_LAND_POPULATION=0
                            else
                                TEMPLE_LAND_PUBLIC_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Public Land Encroached'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                    
                    TEMPLE_LAND_RENTED_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Rented'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $TEMPLE_LAND_RENTED_HOUSES -lt 1 ]] || [[ ! $TEMPLE_LAND_RENTED_HOUSES ]]
                            then
                                TEMPLE_LAND_RENTED_HOUSES=0
                                TEMPLE_LAND_RENTED_POPULATION=0
                            else
                                TEMPLE_LAND_RENTED_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Rented'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                    TEMPLE_LAND_NO_TENURESTATUS_HOUSES=$(($SUM_TEMPLE_LAND_HOUSES-$TEMPLE_LAND_PATTA_HOUSES-$TEMPLE_LAND_OTHERS_HOUSES-$TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES-$TEMPLE_LAND_PRIVATE_LAND_HOUSES-$TEMPLE_LAND_PUBLIC_LAND_HOUSES-$TEMPLE_LAND_RENTED_HOUSES))
                        if [[ $TEMPLE_LAND_NO_TENURESTATUS_HOUSES -lt 1 ]] || [[ ! $TEMPLE_LAND_NO_TENURESTATUS_HOUSES ]]
                            then
                                TEMPLE_LAND_NO_TENURESTATUS_HOUSES=0
                                TEMPLE_LAND_NO_TENURESTATUS_POPULATION=0
                            else
                                TEMPLE_LAND_NO_TENURESTATUS_POPULATION=$(($SUM_TEMPLE_LAND_POPULATION-$TEMPLE_LAND_PATTA_POPULATION-$TEMPLE_LAND_OTHERS_POPULATION-$TEMPLE_LAND_POSSESSION_CERTIFICATE_POPULATION-$TEMPLE_LAND_PRIVATE_LAND_POPULATION-$TEMPLE_LAND_PUBLIC_LAND_POPULATION-$TEMPLE_LAND_RENTED_POPULATION))
                        fi
                    
# Lands without ownership data
       
        # Total number of lands without ownership:
        v.extract -r input=clipped_lands where="$COLUMN_OWNERSHIP='Govt Reserved' OR $COLUMN_OWNERSHIP='Govt Forest' OR $COLUMN_OWNERSHIP='Govt' OR $COLUMN_OWNERSHIP='Forest Department' OR $COLUMN_OWNERSHIP='Temple/Trustee' OR $COLUMN_OWNERSHIP='Private' OR $COLUMN_OWNERSHIP='Private Forest'" output=clipped_lands_no_ownership --overwrite --quiet
            SUM_NUMBER_NO_OWNERSHIP_LANDS=$(v.db.univar -g map=clipped_lands_no_ownership column=cat | head -n1 | tail -n1 | cut -d"=" -f2)
            
            # Total area of of lands without ownership (m2):
            SUM_AREA_NO_OWNERSHIP_LANDS=0
            COLUMN=$(v.report map=clipped_lands_no_ownership option=area units=meters sort=asc | head -n1 | sed s''/[a-z,A-Z,0-9,_]//g | wc -c)
            for i in $(v.report map=clipped_lands_no_ownership option=area units=meters sort=asc | cut -d"|" -f$COLUMN);do
                SUM_AREA_NO_OWNERSHIP_LANDS=$(echo "scale=2;$i+$SUM_AREA_NO_OWNERSHIP_LANDS" | bc)
            done
            SUM_AREA_NO_OWNERSHIP_LANDS=$(echo $SUM_AREA_NO_OWNERSHIP_LANDS | cut -d"." -f1)
            
                    
            # Calculating number of households and habitants on PRIVATE owned area by the legal status of the house
                v.clip input=clipped_households clip=clipped_lands_no_ownership output=households_on_no_ownership_land --overwrite
                CLIPPED_MAP=households_on_no_ownership_land
                
                    SUM_NO_OWNERSHIP_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members | head -n1 |  cut -d":" -f2 | sed s'/ //'g)
                    SUM_NO_OWNERSHIP_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members | tail -n1 | cut -d":" -f2 | sed s'/ //'g)

                    NO_OWNERSHIP_LAND_PATTA_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Patta'" | head -n1 |  cut -d":" -f2 | sed s'/ //'g)
                        if [[ $NO_OWNERSHIP_LAND_PATTA_HOUSES -lt 1 ]] || [[ ! $NO_OWNERSHIP_LAND_PATTA_HOUSES ]]
                            then
                                NO_OWNERSHIP_LAND_PATTA_HOUSES=0
                                NO_OWNERSHIP_LAND_PATTA_POPULATION=0
                            else
                                NO_OWNERSHIP_LAND_PATTA_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Patta'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    NO_OWNERSHIP_LAND_OTHERS_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='others'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $NO_OWNERSHIP_LAND_OTHERS_HOUSES -lt 1 ]] || [[ ! $NO_OWNERSHIP_LAND_OTHERS_HOUSES ]]
                            then
                                NO_OWNERSHIP_LAND_OTHERS_HOUSES=0
                                NO_OWNERSHIP_LAND_OTHERS_POPULATION=0
                            else
                                NO_OWNERSHIP_LAND_OTHERS_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='others'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Possession Certificate/Occupancy Right'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES -lt 1 ]] || [[ ! $NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES ]]
                            then
                                NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES=0
                                NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_POPULATION=0
                            else
                                NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Possession Certificate/Occupancy Right'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Private Land Encroached'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES -lt 1 ]] || [[ ! $NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES ]]
                            then
                                NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES=0
                                NO_OWNERSHIP_LAND_PRIVATE_LAND_POPULATION=0
                            else
                                NO_OWNERSHIP_LAND_PRIVATE_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Private Land Encroached'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                    NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Public Land Encroached'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES -lt 1 ]] || [[ ! $NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES ]]
                            then
                                NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES=0
                                NO_OWNERSHIP_LAND_PUBLIC_LAND_POPULATION=0
                            else
                                NO_OWNERSHIP_LAND_PUBLIC_LAND_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Public Land Encroached'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)
                        fi
                        
                    NO_OWNERSHIP_LAND_RENTED_HOUSES=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Rented'" | head -n1 | cut -d":" -f2 | sed s'/ //'g)
                        if [[ $NO_OWNERSHIP_LAND_RENTED_HOUSES -lt 1 ]] || [[ ! $NO_OWNERSHIP_LAND_RENTED_HOUSES ]]
                            then
                                NO_OWNERSHIP_LAND_RENTED_HOUSES=0
                                NO_OWNERSHIP_LAND_RENTED_POPULATION=0
                            else
                                NO_OWNERSHIP_LAND_RENTED_POPULATION=$(v.db.univar map=$CLIPPED_MAP column=total_family_members where="house_tenure_status='Rented'" | tail -n1 | cut -d":" -f2 | sed s'/ //'g)                    
                        fi
                    NO_OWNERSHIP_LAND_NO_TENURESTATUS_HOUSES=$(($SUM_NO_OWNERSHIP_LAND_HOUSES-$NO_OWNERSHIP_LAND_PATTA_HOUSES-$NO_OWNERSHIP_LAND_OTHERS_HOUSES-$NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES-$NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES-$NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES-$NO_OWNERSHIP_LAND_RENTED_HOUSES))
                        if [[ $NO_OWNERSHIP_LAND_NO_TENURESTATUS_HOUSES -lt 1 ]] || [[ ! $NO_OWNERSHIP_LAND_NO_TENURESTATUS_HOUSES ]]
                            then
                                NO_OWNERSHIP_LAND_NO_TENURESTATUS_HOUSES=0
                                NO_OWNERSHIP_LAND_NO_TENURESTATUS_POPULATION=0
                            else
                                NO_OWNERSHIP_LAND_NO_TENURESTATUS_POPULATION=$(($SUM_NO_OWNERSHIP_LAND_POPULATION-$NO_OWNERSHIP_LAND_PATTA_POPULATION-$NO_OWNERSHIP_LAND_OTHERS_POPULATION-$NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_POPULATION-$NO_OWNERSHIP_LAND_PRIVATE_LAND_POPULATION-$NO_OWNERSHIP_LAND_PUBLIC_LAND_POPULATION-$NO_OWNERSHIP_LAND_RENTED_POPULATION))
                        fi

# Summed land data (in this case this means: summed data for query area, represented by query_area_1 map)

        TOTAL_NUMBER_OF_LANDS=$(($SUM_NUMBER_GOV_LANDS+$SUM_NUMBER_PRIVATE_LANDS+$SUM_NUMBER_TEMPLE_LANDS+$SUM_NUMBER_NO_OWNERSHIP_LANDS))
        TOTAL_AREA_OF_LANDS=$(($SUM_AREA_OF_GOV_OWNED_LANDS+$SUM_AREA_OF_PRIVATE_OWNED_LANDS+$SUM_AREA_OF_TEMPLE_OWNED_LANDS+$SUM_AREA_NO_OWNERSHIP_LANDS))
        TOTAL_NUMBER_OF_HOUSES=$(($SUM_GOV_LAND_HOUSES+$SUM_PRIVATE_LAND_HOUSES+$SUM_TEMPLE_LAND_HOUSES+$SUM_NO_OWNERSHIP_LAND_HOUSES))
        TOTAL_POPULATION_OF_LANDS=$(($SUM_GOV_LAND_POPULATION+$SUM_PRIVATE_LAND_POPULATION+$SUM_TEMPLE_LAND_POPULATION+$SUM_NO_OWNERSHIP_LAND_POPULATION))

# --------------------------------------
# text and numberic data output in odf and pdf format too

    #Calculations for government owned lands
        GOV_LAND_OTHERS_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_OTHERS_HOUSES/$SUM_GOV_LAND_HOUSES)*100" | bc)
        GOV_LAND_OTHERS_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_OTHERS_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        GOV_LAND_OTHERS_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_OTHERS_POPULATION/$SUM_GOV_LAND_POPULATION)*100" | bc)
        GOV_LAND_OTHERS_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_OTHERS_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
                
        GOV_LAND_PATTA_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_PATTA_HOUSES/$SUM_GOV_LAND_HOUSES)*100" | bc)
        GOV_LAND_PATTA_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_PATTA_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        GOV_LAND_PATTA_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_PATTA_POPULATION/$SUM_GOV_LAND_POPULATION)*100" | bc)
        GOV_LAND_PATTA_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_PATTA_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        GOV_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_POSSESSION_CERTIFICATE_HOUSES/$SUM_GOV_LAND_HOUSES)*100" | bc)
        GOV_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_POSSESSION_CERTIFICATE_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        GOV_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_POSSESSION_CERTIFICATE_POPULATION/$SUM_GOV_LAND_POPULATION)*100" | bc)
        GOV_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_POSSESSION_CERTIFICATE/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        GOV_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_PRIVATE_LAND_HOUSES/$SUM_GOV_LAND_HOUSES)*100" | bc)
        GOV_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_PRIVATE_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        GOV_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_PRIVATE_LAND_POPULATION/$SUM_GOV_LAND_POPULATION)*100" | bc)
        GOV_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_PRIVATE_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        GOV_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_PUBLIC_LAND_HOUSES/$SUM_GOV_LAND_HOUSES)*100" | bc)
        GOV_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_PUBLIC_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        GOV_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_PUBLIC_LAND_POPULATION/$SUM_GOV_LAND_POPULATION)*100" | bc)
        GOV_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_PUBLIC_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        GOV_LAND_RENTED_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_RENTED_HOUSES/$SUM_GOV_LAND_HOUSES)*100" | bc)
        GOV_LAND_RENTED_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_RENTED_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        GOV_LAND_RENTED_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_RENTED_POPULATION/$SUM_GOV_LAND_POPULATION)*100" | bc)
        GOV_LAND_RENTED_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_RENTED_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        GOV_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_NO_TENURESTATUS_HOUSES/$SUM_GOV_LAND_HOUSES)*100" | bc)
        GOV_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_NO_TENURESTATUS_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        GOV_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($GOV_LAND_NO_TENURESTATUS_POPULATION/$SUM_GOV_LAND_POPULATION)*100" | bc)
        GOV_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($GOV_LAND_NO_TENURESTATUS_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)

        SUM_NUMBER_GOV_LANDS_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_NUMBER_GOV_LANDS/$TOTAL_NUMBER_OF_LANDS)*100" | bc)
        SUM_AREA_OF_GOV_OWNED_LANDS_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_AREA_OF_GOV_OWNED_LANDS/$TOTAL_AREA_OF_LANDS)*100" | bc)
        SUM_GOV_LAND_HOUSES_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_GOV_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        SUM_GOV_LAND_POPULATION_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_GOV_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
    
# Calculations for Private owned lands
        PRIVATE_LAND_OTHERS_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_OTHERS_HOUSES/$SUM_PRIVATE_LAND_HOUSES)*100" | bc)
        PRIVATE_LAND_OTHERS_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_OTHERS_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        PRIVATE_LAND_OTHERS_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_OTHERS_POPULATION/$SUM_PRIVATE_LAND_POPULATION)*100" | bc)
        PRIVATE_LAND_OTHERS_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_OTHERS_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        PRIVATE_LAND_PATTA_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_PATTA_HOUSES/$SUM_PRIVATE_LAND_HOUSES)*100" | bc)
        PRIVATE_LAND_PATTA_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_PATTA_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        PRIVATE_LAND_PATTA_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_PATTA_POPULATION/$SUM_PRIVATE_LAND_POPULATION)*100" | bc)
        PRIVATE_LAND_PATTA_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_PATTA_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES/$SUM_PRIVATE_LAND_HOUSES)*100" | bc)
        PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        PRIVATE_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_POSSESSION_CERTIFICATE_POPULATION/$SUM_PRIVATE_LAND_POPULATION)*100" | bc)
        PRIVATE_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_POSSESSION_CERTIFICATE/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        PRIVATE_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_PRIVATE_LAND_HOUSES/$SUM_PRIVATE_LAND_HOUSES)*100" | bc)
        PRIVATE_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_PRIVATE_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        PRIVATE_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_PRIVATE_LAND_POPULATION/$SUM_PRIVATE_LAND_POPULATION)*100" | bc)
        PRIVATE_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_PRIVATE_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        PRIVATE_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_PUBLIC_LAND_HOUSES/$SUM_PRIVATE_LAND_HOUSES)*100" | bc)
        PRIVATE_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_PUBLIC_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        PRIVATE_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_PUBLIC_LAND_POPULATION/$SUM_PRIVATE_LAND_POPULATION)*100" | bc)
        PRIVATE_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_PUBLIC_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        PRIVATE_LAND_RENTED_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_RENTED_HOUSES/$SUM_PRIVATE_LAND_HOUSES)*100" | bc)
        PRIVATE_LAND_RENTED_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_RENTED_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        PRIVATE_LAND_RENTED_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_RENTED_POPULATION/$SUM_PRIVATE_LAND_POPULATION)*100" | bc)
        PRIVATE_LAND_RENTED_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_RENTED_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        PRIVATE_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_NO_TENURESTATUS_HOUSES/$SUM_PRIVATE_LAND_HOUSES)*100" | bc)
        PRIVATE_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_NO_TENURESTATUS_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        PRIVATE_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($PRIVATE_LAND_NO_TENURESTATUS_POPULATION/$SUM_PRIVATE_LAND_POPULATION)*100" | bc)
        PRIVATE_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($PRIVATE_LAND_NO_TENURESTATUS_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
    
        SUM_NUMBER_PRIVATE_LANDS_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_NUMBER_PRIVATE_LANDS/$TOTAL_NUMBER_OF_LANDS)*100" | bc)
        SUM_AREA_OF_PRIVATE_OWNED_LANDS_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_AREA_OF_PRIVATE_OWNED_LANDS/$TOTAL_AREA_OF_LANDS)*100" | bc)
        SUM_PRIVATE_LAND_HOUSES_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_PRIVATE_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        SUM_PRIVATE_LAND_POPULATION_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_PRIVATE_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
    
 # Calculations for Temple/Trustee owned lands    
        TEMPLE_LAND_OTHERS_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_OTHERS_HOUSES/$SUM_TEMPLE_LAND_HOUSES)*100" | bc)
        TEMPLE_LAND_OTHERS_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_OTHERS_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        TEMPLE_LAND_OTHERS_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_OTHERS_POPULATION/$SUM_TEMPLE_LAND_POPULATION)*100" | bc)
        TEMPLE_LAND_OTHERS_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_OTHERS_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        TEMPLE_LAND_PATTA_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_PATTA_HOUSES/$SUM_TEMPLE_LAND_HOUSES)*100" | bc)
        TEMPLE_LAND_PATTA_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_PATTA_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        TEMPLE_LAND_PATTA_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_PATTA_POPULATION/$SUM_TEMPLE_LAND_POPULATION)*100" | bc)
        TEMPLE_LAND_PATTA_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_PATTA_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES/$SUM_TEMPLE_LAND_HOUSES)*100" | bc)
        TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        TEMPLE_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_POSSESSION_CERTIFICATE_POPULATION/$SUM_TEMPLE_LAND_POPULATION)*100" | bc)
        TEMPLE_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_POSSESSION_CERTIFICATE/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        TEMPLE_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_PRIVATE_LAND_HOUSES/$SUM_TEMPLE_LAND_HOUSES)*100" | bc)
        TEMPLE_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_PRIVATE_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        TEMPLE_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_PRIVATE_LAND_POPULATION/$SUM_TEMPLE_LAND_POPULATION)*100" | bc)
        TEMPLE_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_PRIVATE_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        TEMPLE_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_PUBLIC_LAND_HOUSES/$SUM_TEMPLE_LAND_HOUSES)*100" | bc)
        TEMPLE_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_PUBLIC_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        TEMPLE_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_PUBLIC_LAND_POPULATION/$SUM_TEMPLE_LAND_POPULATION)*100" | bc)
        TEMPLE_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_PUBLIC_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        TEMPLE_LAND_RENTED_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_RENTED_HOUSES/$SUM_TEMPLE_LAND_HOUSES)*100" | bc)
        TEMPLE_LAND_RENTED_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_RENTED_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        TEMPLE_LAND_RENTED_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_RENTED_POPULATION/$SUM_TEMPLE_LAND_POPULATION)*100" | bc)
        TEMPLE_LAND_RENTED_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_RENTED_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        TEMPLE_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_NO_TENURESTATUS_HOUSES/$SUM_TEMPLE_LAND_HOUSES)*100" | bc)
        TEMPLE_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_NO_TENURESTATUS_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        TEMPLE_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($TEMPLE_LAND_NO_TENURESTATUS_POPULATION/$SUM_TEMPLE_LAND_POPULATION)*100" | bc)
        TEMPLE_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($TEMPLE_LAND_NO_TENURESTATUS_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        SUM_NUMBER_TEMPLE_LANDS_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_NUMBER_TEMPLE_LANDS/$TOTAL_NUMBER_OF_LANDS)*100" | bc)
        SUM_AREA_OF_TEMPLE_OWNED_LANDS_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_AREA_OF_TEMPLE_OWNED_LANDS/$TOTAL_AREA_OF_LANDS)*100" | bc)
        SUM_TEMPLE_LAND_HOUSES_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_TEMPLE_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        SUM_TEMPLE_LAND_POPULATION_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_TEMPLE_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)

# Calculations for lands without ownership data
        NO_OWNERSHIP_LAND_OTHERS_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_OTHERS_HOUSES/$SUM_NO_OWNERSHIP_LAND_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_OTHERS_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_OTHERS_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_OTHERS_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_OTHERS_POPULATION/$SUM_NO_OWNERSHIP_LAND_POPULATION)*100" | bc)
        NO_OWNERSHIP_LAND_OTHERS_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_OTHERS_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        NO_OWNERSHIP_LAND_PATTA_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PATTA_HOUSES/$SUM_NO_OWNERSHIP_LAND_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_PATTA_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PATTA_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_PATTA_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PATTA_POPULATION/$SUM_NO_OWNERSHIP_LAND_POPULATION)*100" | bc)
        NO_OWNERSHIP_LAND_PATTA_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PATTA_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES/$SUM_NO_OWNERSHIP_LAND_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_POPULATION/$SUM_NO_OWNERSHIP_LAND_POPULATION)*100" | bc)
        NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES/$SUM_NO_OWNERSHIP_LAND_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PRIVATE_LAND_POPULATION/$SUM_NO_OWNERSHIP_LAND_POPULATION)*100" | bc)
        NO_OWNERSHIP_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PRIVATE_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES/$SUM_NO_OWNERSHIP_LAND_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PUBLIC_LAND_POPULATION/$SUM_NO_OWNERSHIP_LAND_POPULATION)*100" | bc)
        NO_OWNERSHIP_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_PUBLIC_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        NO_OWNERSHIP_LAND_RENTED_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_RENTED_HOUSES/$SUM_NO_OWNERSHIP_LAND_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_RENTED_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_RENTED_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_RENTED_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_RENTED_POPULATION/$SUM_NO_OWNERSHIP_LAND_POPULATION)*100" | bc)
        NO_OWNERSHIP_LAND_RENTED_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_RENTED_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        NO_OWNERSHIP_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_NO_TENURESTATUS_HOUSES/$SUM_NO_OWNERSHIP_LAND_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_NO_TENURESTATUS_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        NO_OWNERSHIP_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_SUM=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_NO_TENURESTATUS_POPULATION/$SUM_NO_OWNERSHIP_LAND_POPULATION)*100" | bc)
        NO_OWNERSHIP_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_TOTAL=$(echo "scale=3 ;($NO_OWNERSHIP_LAND_NO_TENURESTATUS_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        
        SUM_NUMBER_NO_OWNERSHIP_LANDS_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_NUMBER_NO_OWNERSHIP_LANDS/$TOTAL_NUMBER_OF_LANDS)*100" | bc)
        SUM_AREA_OF_NO_OWNERSHIP_OWNED_LANDS_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_AREA_OF_NO_OWNERSHIP_OWNED_LANDS/$TOTAL_AREA_OF_LANDS)*100" | bc)
        SUM_NO_OWNERSHIP_LAND_HOUSES_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_NO_OWNERSHIP_LAND_HOUSES/$TOTAL_NUMBER_OF_HOUSES)*100" | bc)
        SUM_NO_OWNERSHIP_LAND_POPULATION_TOTAL_PERCENTAGE=$(echo "scale=3 ;($SUM_NO_OWNERSHIP_LAND_POPULATION/$TOTAL_POPULATION_OF_LANDS)*100" | bc)
        

# To create an ods output, first have to save data as csv. This csv file will converted into ods format. 
        
rm -f $MODULE/output.csv
touch $MODULE/output.csv

echo "Government,Patta,-,-,-,-,-,-,$GOV_LAND_PATTA_HOUSES,$GOV_LAND_PATTA_HOUSES_PERCENTAGE_SUM,$GOV_LAND_PATTA_HOUSES_PERCENTAGE_TOTAL,$GOV_LAND_PATTA_POPULATION,$GOV_LAND_PATTA_POPULATION_PERCENTAGE_SUM,$GOV_LAND_PATTA_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Possesion Certificate/Occupancy Right,-,-,-,-,-,-,$GOV_LAND_POSSESSION_CERTIFICATE_HOUSES,$GOV_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_SUM,$GOV_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_TOTAL,$GOV_LAND_POSSESSION_CERTIFICATE_POPULATION,$GOV_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_SUM,$GOV_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Private land encroached,-,-,-,-,-,-,$GOV_LAND_PRIVATE_LAND_HOUSES,$GOV_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_SUM,$GOV_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_TOTAL,$GOV_LAND_PRIVATE_LAND_POPULATION,$GOV_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_SUM,$GOV_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Public land encroached,-,-,-,-,-,-,$GOV_LAND_PUBLIC_LAND_HOUSES,$GOV_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_SUM,$GOV_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_TOTAL,$GOV_LAND_PUBLIC_LAND_POPULATION,$GOV_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_SUM,$GOV_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Rented,-,-,-,-,-,-,$GOV_LAND_RENTED_HOUSES,$GOV_LAND_RENTED_HOUSES_PERCENTAGE_SUM,$GOV_LAND_RENTED_HOUSES_PERCENTAGE_TOTAL,$GOV_LAND_RENTED_POPULATION,$GOV_LAND_RENTED_POPULATION_PERCENTAGE_SUM,$GOV_LAND_RENTED_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Other,-,-,-,-,-,-,$GOV_LAND_OTHERS_HOUSES,$GOV_LAND_OTHERS_HOUSES_PERCENTAGE_SUM,$GOV_LAND_OTHERS_HOUSES_PERCENTAGE_TOTAL,$GOV_LAND_OTHERS_POPULATION,$GOV_LAND_OTHERS_POPULATION_PERCENTAGE_SUM,$GOV_LAND_OTHERS_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",no house tenure data,-,-,-,-,-,-,$GOV_LAND_NO_TENURESTATUS_HOUSES ,$GOV_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_SUM,$GOV_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_TOTAL,$GOV_LAND_NO_TENURESTATUS_POPULATION,$GOV_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_SUM,$GOV_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",,,,,,,,,,,,," >> $MODULE/output.csv
echo ",Sum,$SUM_NUMBER_GOV_LANDS,100,$SUM_NUMBER_GOV_LANDS_TOTAL_PERCENTAGE,$SUM_AREA_OF_GOV_OWNED_LANDS,100,$SUM_AREA_OF_GOV_OWNED_LANDS_TOTAL_PERCENTAGE,$SUM_GOV_LAND_HOUSES,100,$SUM_GOV_LAND_HOUSES_TOTAL_PERCENTAGE,$SUM_GOV_LAND_POPULATION,100,$SUM_GOV_LAND_POPULATION_TOTAL_PERCENTAGE" >> $MODULE/output.csv
echo ",,,,,,,,,,,,," >> $MODULE/output.csv

echo "Private,Patta,-,-,-,-,-,-,$PRIVATE_LAND_PATTA_HOUSES,$PRIVATE_LAND_PATTA_HOUSES_PERCENTAGE_SUM,$PRIVATE_LAND_PATTA_HOUSES_PERCENTAGE_TOTAL,$PRIVATE_LAND_PATTA_POPULATION,$PRIVATE_LAND_PATTA_POPULATION_PERCENTAGE_SUM,$PRIVATE_LAND_PATTA_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Possesion Certificate/Occupancy Right,-,-,-,-,-,-,$PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES,$PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_SUM,$PRIVATE_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_TOTAL,$PRIVATE_LAND_POSSESSION_CERTIFICATE_POPULATION,$PRIVATE_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_SUM,$PRIVATE_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Private land encroached,-,-,-,-,-,-,$PRIVATE_LAND_PRIVATE_LAND_HOUSES,$PRIVATE_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_SUM,$PRIVATE_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_TOTAL,$PRIVATE_LAND_PRIVATE_LAND_POPULATION,$PRIVATE_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_SUM,$PRIVATE_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Public land encroached,-,-,-,-,-,-,$PRIVATE_LAND_PUBLIC_LAND_HOUSES,$PRIVATE_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_SUM,$PRIVATE_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_TOTAL,$PRIVATE_LAND_PUBLIC_LAND_POPULATION,$PRIVATE_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_SUM,$PRIVATE_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Rented,-,-,-,-,-,-,$PRIVATE_LAND_RENTED_HOUSES,$PRIVATE_LAND_RENTED_HOUSES_PERCENTAGE_SUM,$PRIVATE_LAND_RENTED_HOUSES_PERCENTAGE_TOTAL,$PRIVATE_LAND_RENTED_POPULATION,$PRIVATE_LAND_RENTED_POPULATION_PERCENTAGE_SUM,$PRIVATE_LAND_RENTED_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Other,-,-,-,-,-,-,$PRIVATE_LAND_OTHERS_HOUSES,$PRIVATE_LAND_OTHERS_HOUSES_PERCENTAGE_SUM,$PRIVATE_LAND_OTHERS_HOUSES_PERCENTAGE_TOTAL,$PRIVATE_LAND_OTHERS_POPULATION,$PRIVATE_LAND_OTHERS_POPULATION_PERCENTAGE_SUM,$PRIVATE_LAND_OTHERS_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",no house tenure data,-,-,-,-,-,-,$PRIVATE_LAND_NO_TENURESTATUS_HOUSES ,$PRIVATE_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_SUM,$PRIVATE_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_TOTAL,$PRIVATE_LAND_NO_TENURESTATUS_POPULATION,$PRIVATE_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_SUM,$PRIVATE_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",,,,,,,,,,,,," >> $MODULE/output.csv
echo ",Sum,$SUM_NUMBER_PRIVATE_LANDS,100,$SUM_NUMBER_PRIVATE_LANDS_TOTAL_PERCENTAGE,$SUM_AREA_OF_PRIVATE_OWNED_LANDS,100,$SUM_AREA_OF_PRIVATE_OWNED_LANDS_TOTAL_PERCENTAGE,$SUM_PRIVATE_LAND_HOUSES,100,$SUM_PRIVATE_LAND_HOUSES_TOTAL_PERCENTAGE,$SUM_PRIVATE_LAND_POPULATION,100,$SUM_PRIVATE_LAND_POPULATION_TOTAL_PERCENTAGE" >> $MODULE/output.csv
echo ",,,,,,,,,,,,," >> $MODULE/output.csv

echo "Temple/Trustee,Patta,-,-,-,-,-,-,$TEMPLE_LAND_PATTA_HOUSES,$TEMPLE_LAND_PATTA_HOUSES_PERCENTAGE_SUM,$TEMPLE_LAND_PATTA_HOUSES_PERCENTAGE_TOTAL,$TEMPLE_LAND_PATTA_POPULATION,$TEMPLE_LAND_PATTA_POPULATION_PERCENTAGE_SUM,$TEMPLE_LAND_PATTA_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Possesion Certificate/Occupancy Right,-,-,-,-,-,-,$TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES,$TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_SUM,$TEMPLE_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_TOTAL,$TEMPLE_LAND_POSSESSION_CERTIFICATE_POPULATION,$TEMPLE_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_SUM,$TEMPLE_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Private land encroached,-,-,-,-,-,-,$TEMPLE_LAND_PRIVATE_LAND_HOUSES,$TEMPLE_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_SUM,$TEMPLE_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_TOTAL,$TEMPLE_LAND_PRIVATE_LAND_POPULATION,$TEMPLE_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_SUM,$TEMPLE_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Public land encroached,-,-,-,-,-,-,$TEMPLE_LAND_PUBLIC_LAND_HOUSES,$TEMPLE_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_SUM,$TEMPLE_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_TOTAL,$TEMPLE_LAND_PUBLIC_LAND_POPULATION,$TEMPLE_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_SUM,$TEMPLE_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Rented,-,-,-,-,-,-,$TEMPLE_LAND_RENTED_HOUSES,$TEMPLE_LAND_RENTED_HOUSES_PERCENTAGE_SUM,$TEMPLE_LAND_RENTED_HOUSES_PERCENTAGE_TOTAL,$TEMPLE_LAND_RENTED_POPULATION,$TEMPLE_LAND_RENTED_POPULATION_PERCENTAGE_SUM,$TEMPLE_LAND_RENTED_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Other,-,-,-,-,-,-,$TEMPLE_LAND_OTHERS_HOUSES,$TEMPLE_LAND_OTHERS_HOUSES_PERCENTAGE_SUM,$TEMPLE_LAND_OTHERS_HOUSES_PERCENTAGE_TOTAL,$TEMPLE_LAND_OTHERS_POPULATION,$TEMPLE_LAND_OTHERS_POPULATION_PERCENTAGE_SUM,$TEMPLE_LAND_OTHERS_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",no house tenure data,-,-,-,-,-,-,$TEMPLE_LAND_NO_TENURESTATUS_HOUSES ,$TEMPLE_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_SUM,$TEMPLE_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_TOTAL,$TEMPLE_LAND_NO_TENURESTATUS_POPULATION,$TEMPLE_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_SUM,$TEMPLE_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",,,,,,,,,,,,," >> $MODULE/output.csv
echo ",Sum,$SUM_NUMBER_TEMPLE_LANDS,100,$SUM_NUMBER_TEMPLE_LANDS_TOTAL_PERCENTAGE,$SUM_AREA_OF_TEMPLE_OWNED_LANDS,100,$SUM_AREA_OF_TEMPLE_OWNED_LANDS_TOTAL_PERCENTAGE,$SUM_TEMPLE_LAND_HOUSES,100,$SUM_TEMPLE_LAND_HOUSES_TOTAL_PERCENTAGE,$SUM_TEMPLE_LAND_POPULATION,100,$SUM_TEMPLE_LAND_POPULATION_TOTAL_PERCENTAGE" >> $MODULE/output.csv
echo ",,,,,,,,,,,,," >> $MODULE/output.csv

echo "No Land ownership data,Patta,-,-,-,-,-,-,$NO_OWNERSHIP_LAND_PATTA_HOUSES,$NO_OWNERSHIP_LAND_PATTA_HOUSES_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_PATTA_HOUSES_PERCENTAGE_TOTAL,$NO_OWNERSHIP_LAND_PATTA_POPULATION,$NO_OWNERSHIP_LAND_PATTA_POPULATION_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_PATTA_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Possesion Certificate/Occupancy Right,-,-,-,-,-,-,$NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES,$NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_HOUSES_PERCENTAGE_TOTAL,$NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_POPULATION,$NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_POSSESSION_CERTIFICATE_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Private land encroached,-,-,-,-,-,-,$NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES,$NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_PRIVATE_LAND_HOUSES_PERCENTAGE_TOTAL,$NO_OWNERSHIP_LAND_PRIVATE_LAND_POPULATION,$NO_OWNERSHIP_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_PRIVATE_LAND_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Public land encroached,-,-,-,-,-,-,$NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES,$NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_PUBLIC_LAND_HOUSES_PERCENTAGE_TOTAL,$NO_OWNERSHIP_LAND_PUBLIC_LAND_POPULATION,$NO_OWNERSHIP_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_PUBLIC_LAND_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Rented,-,-,-,-,-,-,$NO_OWNERSHIP_LAND_RENTED_HOUSES,$NO_OWNERSHIP_LAND_RENTED_HOUSES_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_RENTED_HOUSES_PERCENTAGE_TOTAL,$NO_OWNERSHIP_LAND_RENTED_POPULATION,$NO_OWNERSHIP_LAND_RENTED_POPULATION_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_RENTED_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",Other,-,-,-,-,-,-,$NO_OWNERSHIP_LAND_OTHERS_HOUSES,$NO_OWNERSHIP_LAND_OTHERS_HOUSES_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_OTHERS_HOUSES_PERCENTAGE_TOTAL,$NO_OWNERSHIP_LAND_OTHERS_POPULATION,$NO_OWNERSHIP_LAND_OTHERS_POPULATION_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_OTHERS_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",no house tenure data,-,-,-,-,-,-,$NO_OWNERSHIP_LAND_NO_TENURESTATUS_HOUSES ,$NO_OWNERSHIP_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_NO_TENURESTATUS_HOUSES_PERCENTAGE_TOTAL,$NO_OWNERSHIP_LAND_NO_TENURESTATUS_POPULATION,$NO_OWNERSHIP_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_SUM,$NO_OWNERSHIP_LAND_NO_TENURESTATUS_POPULATION_PERCENTAGE_TOTAL" >> $MODULE/output.csv
echo ",,,,,,,,,,,,," >> $MODULE/output.csv
echo ",Sum,$SUM_NUMBER_NO_OWNERSHIP_LANDS,100,$SUM_NUMBER_NO_OWNERSHIP_LANDS_TOTAL_PERCENTAGE,$SUM_AREA_OF_NO_OWNERSHIP_OWNED_LANDS,100,$SUM_AREA_OF_NO_OWNERSHIP_OWNED_LANDS_TOTAL_PERCENTAGE,$SUM_NO_OWNERSHIP_LAND_HOUSES,100,$SUM_NO_OWNERSHIP_LAND_HOUSES_TOTAL_PERCENTAGE,$SUM_NO_OWNERSHIP_LAND_POPULATION,100,$SUM_NO_OWNERSHIP_LAND_POPULATION_TOTAL_PERCENTAGE" >> $MODULE/output.csv
echo ",,,,,,,,,,,,," >> $MODULE/output.csv
echo ",Total,$TOTAL_NUMBER_OF_LANDS,-,100,$TOTAL_AREA_OF_LANDS,-,100,$TOTAL_NUMBER_OF_HOUSES,-,100,$TOTAL_POPULATION_OF_LANDS,-,100" >> $MODULE/output.csv



        # First: creating a multilayer map for pdf output. For this end has to use maps and an external style file
        
            g.region vector=selection@PERMANENT
            
            ps.map input=$MODULE/ps_param_1 output=$MODULE/temp_query_map_1.ps --overwrite
            ps2pdf $MODULE/temp_query_map_1.ps $MODULE/temp_query_map_1.pdf

            g.region vector=query_area_1

            ps.map input=$MODULE/ps_param_2 output=$MODULE/temp_query_map_2.ps --overwrite
            ps2pdf $MODULE/temp_query_map_2.ps $MODULE/temp_query_map_2.pdf
 
    # Second: Exporting results as an ods file. For this end, a predefined table, as pattern is used (sample.ods)
        ~/cityapp/scripts/external/csv2odf/csv2odf -S2 $MODULE/output.csv $MODULE/template.ods $MODULE/result.ods
        
############################
                        
exit

################
################
################
################


