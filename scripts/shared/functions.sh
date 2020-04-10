# version 1.3
# CityApp function
# This file contains functions of CityApp bash scripts. Funcions are in alphabetical order, A short description can be found for each function.
# 2020. április 10.
# Author: BUGYA Titusz, CityScienceLab -- Hamburg, Germany

#
# -- Functions ---------------------------------
#

Add_Osm ()
    #This is to import an Open street map vector map file. Parameters: {filename to import,layer name, output filename for the GRASS}
    {
    echo "Add_Osm" > $VARIABLES/still_working
    grass -f $GRASS/$MAPSET --exec v.in.ogr -o input=$1 layer=$2 output=$3 --overwrite --quiet
    rm -f $VARIABLES/still_working
    }

Add_Raster ()
    {
    #This is to import geotiff raster maps. Parameters: 
    echo "Add_Raster" > $VARIABLES/still_working
    grass -f $GRASS/$MAPSET --exec r.import input=$1 output=$2 --overwrite
    # grass -f $GRASS/$MAPSET --exec r.in.gdal -o -l -a -r input=$1 output=$2 --overwrite
    rm -f $VARIABLES/still_working
    }

Add_Vector ()
    #This is to import a vector map file. Parameters: {filename to import,output filename for the GRASS}
    {
    echo "Add_Vector" > $VARIABLES/still_working
    grass -f $GRASS/$MAPSET --exec v.import input=$1 output=$2 --overwrite
#    grass -f $GRASS/$MAPSET --exec v.in.ogr -o input=$1 output=$2 --overwrite
    rm -f $VARIABLES/still_working
    }
    
Area_To_Raster ()
    # This function is to convert vector area into raster format. Using this, check first the resolution of your GRASS region! Parameters: {vector to convert, raster output name, sql statement, attribute column to get raster values} If the last two parameter is 0, only the input name and output name will considered: a simple vector-raster conversion. In this case GRASS will convert vector input to raster output, and each raster will have the same value: 1.
    {
    echo "Area_To_Raster" > $VARIABLES/still_working
    if [ $3 -eq 0 ] && [ $4 -eq 0 ]
        then
            grass -f $GRASS/$MAPSET --exec v.to.rast input=$1 type=area output=$2 val=1 --overwrite --quiet
        else
            grass -f $GRASS/$MAPSET --exec v.to.rast input=$1 type=area output=$2 where=$3 use=attr attribute_column=$4 --overwrite --quiet
    fi
    rm -f $VARIABLES/still_working
    }
    
Centroid_Query_Raster ()
    # Query raster values under centroid points of specified vector map. Output will send to a file. Parameters: {Vector map with centroids,raster map to qery,output file for query results}
    {
    grass -f $GRASS/$MAPSET --exec  v.what.rast -p map=$1 type=centroid raster=$2 --overwrite --quiet > $3 
    }

Centroid_To_Raster ()
    # This function is to convert the centroid of a vector area into raster format. Using this, check first the resolution of your GRASS region! Parameters: {vector to convert, raster output name, sql statement, attribute column to get raster values} If the last two parameter is 0, only the input name and output name will considered: a simple vector-raster conversion. In this case GRASS will convert vector input to raster output, and each raster will have the same value: 1.
    {
    if [ $3 -eq 0 ] && [ $4 -eq 0 ]
        then
            grass -f $GRASS/$MAPSET --exec v.to.rast input=$1 type=centroid output=$2 val=1 --overwrite --quiet
        else
            grass -f $GRASS/$MAPSET --exec v.to.rast input=$1 type=centroid output=$2 where=$3 use=attr attribute_column=$4 --overwrite --quiet
    fi
    touch $VARIABLES/still_working
    echo "Add_Osm" > $VARIABLES/still_working
    }
    
Close_Process ()
    {
    # This is to clean everything properly after finishing the module.
    if [ -e $VARIABLES/subprocess ]
        then
            rm -f $MODULE/temp_*
            rm -f $MESSAGE_SENT/*
            rm $BROWSER/leave_session
            rm -f $BROWSER/request
    fi
    
    if [ -e $VARIABLES/still_working ]
        then
            inotifywait -e delete $VARIABLES/still_working
                            
            rm -f $MODULE/temp_*
            rm -f $MESSAGE_SENT/*
            rm $VARIABLES/launch_locked
            rm $BROWSER/leave_session
            rm -f $BROWSER/request
            
            PS_ID=$(ps a | grep $MODULE_NAME | sed s'/[a-z _]//'g | cut -d"/" -f1)
            echo "--------------------"
            echo "Now killing process"
            echo "Pocess: -- $MODULE_NAME -- killed"
            echo "--------------------"
            kill -9 $PS_ID

            touch $BROWSER/launcher_run
        else
            rm -f $MODULE/temp_*
            rm -f $MESSAGE_SENT/*
            rm $VARIABLES/launch_locked
            rm $BROWSER/leave_session
            rm -f $BROWSER/request
            
            PS_ID=$(ps a | grep $MODULE_NAME | sed s'/[a-z _]//'g | cut -d"/" -f1)
            echo "--------------------"
            echo "Now killing process"
            echo "Pocess: -- $MODULE_NAME -- killed"
            echo "--------------------"
            kill -9 $PS_ID

            touch $BROWSER/launcher_run
    fi
    }
    
Count_Lines ()
    # This is to count lines which fits to pattern in a file (normally: this file is the output of Centroid_Query_Raster function). Parameters: {file to analyse,field separator,column (first or second etc...,pattern} For example:    Count_Lines kimenet | 2 4     means:   cat kimenet.txt | cut -d"|" -f2 | grep "4" | wc -l    Output is stdout.
    # There are default values: for field separator: "|". For column number: "2". If you want to use default values, only declare the first two parameter.
    {
    if [ $3 ] && [ $4 ]
        then
           OUTPUT=$(cat $1 | cut -d"$2" -f$3 | grep $4 | wc -l)
        else
            if [ $1 ] && [ $2 ]
                then
                   OUTPUT=$(cat $1 | cut -d"|" -f2 | grep "$2" | wc -l)
            fi
    fi
    }

Geotiff_Out ()
    # Export raster map to Geoserver data dir as Geotiff. Parameters:{map to export, exported name}
    {
    grass $GRASS/$MAPSET --exec r.out.gdal input=$1 output=$GEOSERVER/$2".tif" format=GTiff type=Float64 --overwrite --quiet
    }
    
Gpkg_Out ()
    # This function export a file in the geoserver data dir. Output fileformat can only GPKG. Parameters: {GRASS vector to export,filename after export in geoserver dir}
    {
    grass -f $GRASS/$MAPSET --exec v.out.ogr format=GPKG input=$1 output=$GEOSERVER/$2".gpkg" --overwrite --quiet
    }

Json_To_Text ()
    # Decode from JSON to simle text; Parameters: {$1 -- JSON file in (it is practically the content of the last request), ; $2 -- text file out}
    {
    touch $2
    if [[ $(cat $1 | grep '\{') ]]
        then
            cat $J1 | sed s'/,"/\n/'g | sed s'/{/\n/'g | sed s'/"//'g | sed s'/text://'g | sed s'/list://'g | sed s'/}//'g | sed s'/ //'g | tail -n9 | cut -d":" -f2 > $2
        else
            if [[ $(cat $1 | grep '\[') ]]
                then
                    cat $1 | sed s'/","/\n/'g | sed s'/\[//'g | sed s'/\]//'g | sed s'/"//'g | sed s'/ //'g > $2
                    #cat $1 | sed s'/","/\n/'g | sed s'/\[//'g | sed s'/\]//'g | sed s'/"//'g | sed s'/ //'g | sed s'/,//'g > $2
            fi
    fi
    }

Point_To_Raster ()
    # This function is to convert vector points into raster format. Using this, check first the resolution of your GRASS region! Parameters: {vector to convert, raster output name, sql statement, attribute column to get raster values} If the last two parameter is 0, only the input name and output name will considered: a simple vector-raster conversion. In this case GRASS will convert vector input to raster output, and each raster will have the same value: 1.
    {
    if [ $3 -eq 0 ] && [ $4 -eq 0 ]
        then
            grass -f $GRASS/$MAPSET --exec v.to.rast input=$1 type=point output=$2 val=1 --overwrite --quiet
        else
            grass -f $GRASS/$MAPSET --exec v.to.rast input=$1 type=point output=$2 where=$3 use=attr attribute_column=$4 --overwrite --quiet
    fi
    }
    
Request ()
    {
    CHECK=no
    until [ "$CHECK" == "yes" ];do
        WATCHED=$(inotifywait -e create --format %f $BROWSER)
        if [ "$WATCHED" == request ]
            then
                REQUEST_FILE=request
                REQUEST_PATH=$BROWSER/request
                REQUEST_CONTENT=$(cat $REQUEST_PATH)
                CHECK="yes"
                echo "-------------------------"
                echo $REQUEST_FILE
                echo $REQUEST_PATH
                echo $REQUEST_CONTENT
                echo "-------------------------"
        fi
        if [ "$WATCHED" == leave_session ]
            then
                CHECK="yes"
                echo "-------------------------"
                echo $REQUEST_FILE
                echo $REQUEST_PATH
                echo $REQUEST_CONTENT
                echo "-------------------------"
                Close_Process
                exit
        fi
    done
#    until [ "$REQUEST_FILE" == "request" -o  "$REQUEST_FILE" == "leave_session" ]; do
#        REQUEST_FILE=$(inotifywait -e create --format %f $BROWSER)
#        case $REQUEST_FILE in
#            "leave_session")
#                if [ !-e $VARIABLES/subprocess ]
#                    then
#                        Close_Process
#                        exit
#                fi
#                ;;
#            "request")
#                # FRESH_FILE=$REQUEST_FILE
#                # FRESH_PATH=$BROWSER/$REQUEST_FILE
#                REQUEST_PATH=$BROWSER/request
#                REQUEST_CONTENT=$(cat $REQUEST_PATH)
#                ;;
#        esac
#    done
    rm -f $BROWSER/request
    }
    
Request_Map ()
    # Request map is waiting for a map as input file. The map type is user defined. Therefore thera are options to select import file type. Possible options are: osm,geojson,gpkg,tif (tif, tiff, gtif, gtiff are also laoowed to use). The order has no importance nor the number of options: it is allowes do give only one option or all the four.
    {
    until [ "$CHECK" == "ok" ];do
        REQUEST_FILE=$(inotifywait -e close_write --format %f $BROWSER)
        if [[ "$REQUEST_FILE" =~ "."$1 ]] || [[ "$REQUEST_FILE" =~ "."$2 ]] || [[ "$REQUEST_FILE" =~ "."$3 ]] || [[ "$REQUEST_FILE" =~ "."$4 ]] || [[ "$REQUEST_FILE" =~ "."$5 ]] || [[ "$REQUEST_FILE" =~ "."$6 ]] || [[ "$REQUEST_FILE" =~ "."$7 ]] || [[ "$REQUEST_FILE" =~ "."$8 ]] || [[ "$REQUEST_FILE" =~ "."$9 ]] || [[ "$REQUEST_FILE" =~ "."$10 ]] || [[ "$REQUEST_FILE" =~ "."$11 ]] || [[ "$REQUEST_FILE" =~ "."$12 ]] 
            then
            CHECK="ok"
            FRESH_FILE=$REQUEST_FILE
            FRESH_PATH=$BROWSER/$REQUEST_FILE
            REQUEST_PATH=$BROWSER/$REQUEST_FILE
            #REQUEST_CONTENT=$(cat $REQUEST_FILE)
            #rm -f $BROWSER/*
        fi
        
        if [ "$REQUEST_FILE" == "leave_session" ]
            then
                CHECK="ok"
                Close_Process
                exit
        fi
    done
    }

#Request_Geojson ()
#    {
#    until [ "$CHECK" == "ok" ];do
#        REQUEST_FILE=$(inotifywait -e close_write --format %f $BROWSER)
#        if [[ "$REQUEST_FILE" =~ ".geojson" ]]
#            then
#            CHECK="ok"
#            FRESH_FILE=$REQUEST_FILE
#            FRESH_PATH=$BROWSER/$REQUEST_FILE
#            REQUEST_PATH=$BROWSER/$REQUEST_FILE
#            #REQUEST_CONTENT=$(cat $REQUEST_FILE)
#            #rm -f $BROWSER/*
#        fi
#        
#        if [ "$REQUEST_FILE" == "leave_session" ]
#            then
#                CHECK="ok"
#                Close_Process
#                exit
#        fi
#    done
#    }

Request_Tif ()
    {
    until [ "$CHECK" == "ok" ];do
        REQUEST_FILE=$(inotifywait -e close_write --format %f $BROWSER)
        if [[ "$REQUEST_FILE" =~ ".tif" ]] || [[ "$REQUEST_FILE" =~ ".gtif" ]] || [[ "$REQUEST_FILE" =~ ".tiff" ]]
            then
            CHECK="ok"
            # FRESH_FILE=$REQUEST_FILE
            # FRESH_PATH=$BROWSER/$REQUEST_FILE
            REQUEST_PATH=$BROWSER/$REQUEST_FILE
            #REQUEST_CONTENT=$(cat $REQUEST_FILE)
            #rm -f $BROWSER/*
        fi
        
        if [ "$REQUEST_FILE" == "leave_session" ]
            then
                CHECK="ok"
                Close_Process
                exit
        fi 
    done
    }

Process_Check ()
    # This is to write a file in data_to_client directory in each second. Parameters are: "start" or "stop", and process_description.
    {
    if [ "$1" == "start" ]
        then
            echo $2 > $VARIABLES/process_status
            echo "1" >> $VARIABLES/process_status
            $MODULES/process_check/cityapp_process_check.sh &
    fi


    if [ "$1" == "stop" ]
        then
            echo $2 > $VARIABLES/process_status
            echo "0" >> $VARIABLES/process_status
    fi
    }

Running_Check ()
    # This is to write a file in data_to_client directory in each second. Only parameter is "start" or "stop".
    {
    if [ "$1" == "start" ]
        then
            echo $MODULE_NAME > $VARIABLES/module_status
            echo "1" >> $VARIABLES/module_status
            $MODULES/running_check/cityapp_running_check.sh &
    fi


    if [ "$1" == "stop" ]
        then
            echo $MODULE_NAME > $VARIABLES/module_status
            echo "0" >> $VARIABLES/module_status
    fi
    }
        
Select_Fresh ()
    #This function is to select the last (freshest) file from data_from_browser directory. No parameters
    {
    OUTPUT=$BROWSER/$(ls -ct1 $BROWSER | head -n1)
    }

Send_List ()
    # THis function is to send list, typically issued by GRASS. Normally used send list of available map, or mapsets
    {
    echo $(cat $MESSAGE_TEXT | head -n$1 | tail -n1) > $MESSAGE_SENT/list.$2
    }

Send_Message ()
    # Encode from simple text to JSON. Parameters: {
    # $1 -- type "m": message only, a single line; "s": simple list, long format "l": complex list with a user dialogue message in the first line;
    # $2 -- CityApp message (order number of a single line in the message file of current module);
    # $3 -- Output JSON file (after converting a simple list into JSON);
    # $4 -- list file: this is a list have to transform ito JSON format for the Browser;  }
    
    # New structure:
    
    # $1 -- type "m": message only, a single line; "s": simple list with a user dialogue message in the first line,"l": long format complex list with proprieties and a user dialogue message in the first line;
    # $2 -- CityApp message (order number of a single line in the message file of current module);
    # $3 -- Output JSON file (after converting a simple list into JSON);
    # $4 -- modalType. (actions, list, select)
    # $5 -- action type. Simple "action" for yesnocancel like questions , and "select" for list and other selections
    # $6 -- possible outcomes. format is: ["yes","no","cancel"]
    # $7 -- previously it was $4 -- list file: this is a list have to transform ito JSON format for the Browser;  }

    {
    rm -f $MESSAGE_SENT/*
    case $1 in
        "m")
            echo "{" > $MODULE/temp_message
            echo "\"text\":" >> $MODULE/temp_message
            echo "\"$(cat $MESSAGE_TEXT | head -n$2 | tail -n1) \"," >> $MODULE/temp_message
            echo "\"modalType\": \"$4\"," >> $MODULE/temp_message
            echo "\"$5\": $6" >> $MODULE/temp_message
            echo "}" >> $MODULE/temp_message
            mv $MODULE/temp_message $MESSAGE_SENT/message.$3;;
        "l")        

            LINES=$(cat $7 | wc -l)
            LINE=$(echo $LINES)

            echo "{" > $MODULE/temp_message
            echo "\"text\":" >> $MODULE/temp_message
            echo "\"$(cat $MESSAGE_TEXT | head -n$2 | tail -n1) \"," >> $MODULE/temp_message
            echo "\"modalType\": \"$4\"," >> $MODULE/temp_message
            echo "\"$5\": $6," >> $MODULE/temp_message
            echo "\"list\":" >> $MODULE/temp_message
            echo "{" >> $MODULE/temp_message

            i=1
            until [ $i -gt $LINE ];do
                if [ $i -lt $LINE ]
                    then
                        echo "\""$(cat $7 | head -n$i | tail -n1) | sed s'/:/":"/'g | sed s'/ //'g | sed "/[a-zA-Z0-9]$/s/$/\",/" >> $MODULE/temp_message
                fi
                if [ $i -eq $LINE ]
                    then
                        echo "\""$(cat $7 | head -n$i | tail -n1) | sed s'/:/":"/'g | sed s'/ //'g | sed "/[a-zA-Z0-9]$/s/$/\"/" >> $MODULE/temp_message
                fi
                i=$(($i+1))
            done
            echo "}" >> $MODULE/temp_message
            echo "}" >> $MODULE/temp_message
            mv $MODULE/temp_message $MESSAGE_SENT/message.$3;;
        "s")

            LINES=$(cat $7 | wc -l)
            LINE=$(echo $LINES)

            echo "{" > $MODULE/temp_message
            echo "\"text\":" >> $MODULE/temp_message
            echo "\"$(cat $MESSAGE_TEXT | head -n$2 | tail -n1) \"," >> $MODULE/temp_message
            echo "\"modalType\": \"$4\"," >> $MODULE/temp_message
            echo "\"$5\": $6," >> $MODULE/temp_message
            echo "\"list\":" >> $MODULE/temp_message
            echo "[" >> $MODULE/temp_message

            i=1
            until [ $i -gt $LINE ];do
                if [ $i -lt $LINE ]
                    then
                        echo "\""$(cat $7 | head -n$i | tail -n1) | sed s'/:/":"/'g | sed s'/ //'g | sed "/[a-zA-Z0-9]$/s/$/\",/" >> $MODULE/temp_message
                fi
                if [ $i -eq $LINE ]
                    then
                        echo "\""$(cat $7 | head -n$i | tail -n1) | sed s'/:/":"/'g | sed s'/ //'g | sed "/[a-zA-Z0-9]$/s/$/\"/" >> $MODULE/temp_message
                fi
                i=$(($i+1))
            done
            echo "]" >> $MODULE/temp_message
            echo "}" >> $MODULE/temp_message
            mv $MODULE/temp_message $MESSAGE_SENT/message.$3;;
    esac
    }
    
Set_Region ()
    # Set region. Parameters {vector map,resolution}. First parameter can only a vector map name: If it is defined, the computation region will set to this map. If not defined, region dimensions will not affected, remains as it was. Second option is resolution, have to be defined in decimal degrees (EPSG 4326). Decimal separator is dot (.) If not defined, previously set resolution will not changed. IF you don't want to set vector map, set first parameter to -1. If you don't want to set resolution, set second parameter to -1.
    {
    if [ $1 -eq -1 ]
        then
            grass -f $GRASS/$MAPSET --exec g.region res=$2 --overwrite --quiet
    fi
    
    if [ $2 -eq -1 ]
        then
            grass -f $GRASS/$MAPSET --exec g.region vector=$1 --overwrite --quiet
    fi
    }
    
Vector_Mask ()
    # Simple raster mask from a vector map. Parameter: {vector map to use as MASK}. Output is MASK.
    {
    grass -f $GRASS/$MAPSET --exec r.mask vector=$1 --overwrite --quiet
    }
    
Wait ()
    # Wait until writing and closing a file in the data_from browser directory. No parameters.
    {
    inotifywait -e close_write $BROWSER
    }
