const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html
const fs = require('fs')

const { addVector, getCoordinates, gpkgOut, mapsetExists } = require('./functions')

const BROWSER = process.env.DATA_FROM_BROWSER_DIR
const GRASS = process.env.GRASS_DIR
const VARIABLES = `./variables`
const MAPSET = 'module_1'
const ROAD_POINTS = 0.003
const CONNECT_DISTANCE = 0.003
const AVERAGE_SPEED = 40
const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const BASE_RESOLUTION = 0.0005
const SMOOTH = 4
const TENSION = 30
class ModuleOne {
    constructor() {
        this.messages = {
            0: {
                message_id: 'module_1.0',
                message: "No valid location found. Run Location selector to create a valid location. Module is now exiting."
            },
            1: {
                message_id: 'module_1.1',
                message: { "text": "Start points are required. Do you want to draw start points on the basemap now? If yes, click Yes, then draw one or more point and click Save button. If you want to use an already existing map, select No." }
            },
            2: {
                message_id: 'module_1.2',
                message: { "text": "Select a map (only point maps are supported). Avilable maps are:" }
            },
            3: {
                message_id: 'module_1.3',
                message: { "text": "Via points are optional. If you want to select 'via' points from the map, click Yes. If you want to use an already existing map, select No. If you do not want to use via points, click Cancel." }
            },
            4: {
                message_id: 'module_1.4',
                message: { "text": "Select a map to add to CityApp. Map has to be in Open Street Map format -- osm is the only accepted format." }
            },
            5: {
                message_id: 'module_1.5',
                message: { "text": "Target points are required. If you want to select target points from the map, click Yes. If you want to use an already existing map containing target points, click No. If you want to use the default target points map, click Cancel." }
            },
            6: {
                message_id: 'module_1.6',
                message: { "text": "Select a map (only point maps are supported). Available maps are:" }
            },
            7: {
                message_id: 'module_1.7',
                message: { "text": "Optionally you may define stricken area. If you want to draw area on the map, click Yes. If you want to select a map already containing area, click No. If you do not want to use any area, click Cancel." }
            },
            8: {
                message_id: 'module_1.8',
                message: { "text": "Select a map (only area maps are supported)" }
            },
            9: {
                message_id: 'module_1.9',
                message: { "text": "Set speed reduction ratio for roads of stricken area. This must be a number greater than 0 and less than 1." }
            },
            10: {
                message_id: 'module_1.10',
                message: { "text": "Do you want to set the speed on the road network? If not, the current values will be used." }
            },
            11: {
                message_id: 'module_1.11',
                message: { "text": "Set the speed on the road network." }
            },
            12: {
                message_id: 'module_1.12',
                message: { "text": "Calculations are ready. Display output time maps." }
            }
        }
        this.FROM_POINT = ''
        this.VIA_POINT = ''
        this.VIA = null // via-point modes. possible values: 0, 1, 2
        this.TO_POINT = ''
        this.TO = null // to-point modes. possible values: 0, 1, 2
        this.AREA = null // striken area modes. possible values: 0, 1, 2
        this.AREA_MAP = ''
        this.REDUCING_RATIO = null // Speed reduction ratio for roads of stricken area
        this.ROADS_SPEED = null
    }

    launch() {
        try {
            if (fs.existsSync(`${GRASS}/global/${MAPSET}`)) {
                execSync(`cp "${GRASS}"/global/PERMANENT/WIND "${GRASS}"/global/"${MAPSET}"/WIND`)
            }
            else {
                execSync(`mkdir "${GRASS}"/global/"${MAPSET}"`)
                execSync(`cp "${GRASS}"/global/PERMANENT/WIND "${GRASS}"/global/"${MAPSET}"/WIND`)
                execSync(`cp -r ~/cityapp/grass/skel/* "${GRASS}"/global/"${MAPSET}"`) // question: there's only "~/cityapp/grass/skel_permanent/"
            }
        } catch (err) {
            console.error(err)
        }

        // EAST=$(cat $VARIABLES/coordinate_east) // question: what is this for?
        // NORTH=$(cat $VARIABLES/coordinate_north)

        // # Creating empty maps for ps output, if no related maps are created/selected by user: // question: what is this for?
        // # m1_via_points m1_to_points, m1_stricken_area
        // # If user would create a such map, empty maps will automatically overwritten
        // v.edit map=m1_via_points tool=create
        // v.edit map=m1_to_points tool=create
        // v.edit map=m1_stricken_area tool=create

        if (mapsetExists('PERMANENT')) {
            return this.messages[1]
        }
        return this.messages[6]
    }

    process(message, replyTo) {
        switch (replyTo) {
            case 'module_1.1':
                if (message.toLowerCase() == 'no') {
                    return this.messages[2]
                }
            case 'module_1.2':
                this.FROM_POINT = message
                return this.messages[3]
            case 'module_1.3':
                if (message.toLowerCase() == 'no') {
                    return this.messages[4]
                }
                else if (message.toLowerCase() == 'cancel') {
                    return this.messages[5]
                }
            case 'module_1.4':
                this.VIA = 1
                this.VIA_POINT = message
                return this.messages[5]
            case 'module_1.5':
                if (message.toLowerCase() == 'no') {

                    return this.messages[6]
                }
                else if (message.toLowerCase() == 'cancel') {
                    return this.messages[7]
                }
            case 'module_1.6':
                this.TO = 1
                this.TO_POINT = message
                return this.messages[7]
            case 'module_1.7':
                if (message.toLowerCase() == 'no') {
                    return this.messages[8]
                }
                else if (message.toLowerCase() == 'cancel') {
                    return this.messages[9]
                }
            case 'module_1.8':
                this.AREA = 1
                this.AREA_MAP = message
                return this.messages[9]
            case 'module_1.9':
                this.REDUCING_RATIO = message
                return this.messages[10]
            case 'module_1.10':
                if (message.toLowerCase() == 'yes') {
                    return this.messages[11]
                }
                else if (message.toLowerCase() == 'no') {
                    this.calculate()
                    return this.messages[12]
                }
            case 'module_1.11':
                this.ROADS_SPEED = message // ##?## not used in bash version
                this.calculate()
                return this.messages[12]
        }
    }
    processFile(filename, replyTo) {
        console.log('replyTo: ', replyTo)
        switch (replyTo) {
            /**
             * TODO: draw start point
             */
            case 'module_1.1':
                // grass $GRASS/$MAPSET --exec g.list -m type=vector >$MODULE/temp_list ##?##
                // Add_Vector $REQUEST_PATH m1_from_points
                // Gpkg_Out m1_from_points m1_from_points
                // FROM_POINT=m1_from_points ##?##

                addVector('module_1', `${BROWSER}/${filename}`, 'm1_from_points')
                gpkgOut('module_1', 'm1_from_points', 'm1_from_points')
                this.FROM_POINT = 'm1_from_points'

                return this.messages[3]
            /**
             * TODO: draw via points
             */
            case 'module_1.3':
                // VIA=0            
                // Add_Vector $REQUEST_PATH m1_via_points
                // Gpkg_Out m1_via_points m1_via_points
                // VIA_POINT=m1_via_points ##?##

                this.VIA = 0
                addVector('module_1', `${BROWSER}/${filename}`, 'm1_via_points')
                gpkgOut('module_1', 'm1_via_points', 'm1_via_points')
                this.VIA_POINT = 'm1_via_points'

                return this.messages[5]
            /**
             * TODO: draw target points
             */
            case 'module_1.5':
                // TO=0
                // Add_Vector $FRESH m1_to_points
                // Gpkg_Out m1_to_points m1_to_points
                // TO_POINT=m1_to_points

                this.TO = 0
                addVector('module_1', `${BROWSER}/${filename}`, 'm1_to_points')
                gpkgOut('module_1', 'm1_to_points', 'm1_to_points')
                this.TO_POINT = 'm1_to_points'

                return this.messages[7]
            /**
             * TODO: draw stricken area
             */
            case 'module_1.7':
                // AREA=0
                // Add_Vector $FRESH m1_stricken_area
                // Gpkg_Out m1_stricken_area m1_stricken_area            
                // AREA_MAP="m1_stricken_area"

                this.AREA = 0
                addVector('module_1', `${BROWSER}/${filename}`, 'm1_stricken_area')
                gpkgOut('module_1', 'm1_stricken_area', 'm1_stricken_area')
                this.AREA_MAP = 'm1_stricken_area'

                return this.messages[9]
        }
    }

    calculate() {

        // Creating highways map. This is fundamental for the further work in this module
        execSync(`grass "${GRASS}"/global/module_1 --exec v.extract input=lines@PERMANENT type=line where="highway>0" output=highways --overwrite --quiet`)
        // True data processing Setting region to fit the "selection" map (taken by location_selector), and resolution
        execSync(`grass "${GRASS}"/global/module_1 --exec g.region vector=selection@PERMANENT res=$(cat "${VARIABLES}"/resolution | tail -n1) --overwrite`)

        // connecting from/via/to points to the clipped network, if neccessary. Via points are optional, first have to check if user previously has selected those or not.
        execSync(`grass "${GRASS}"/global/module_1 --exec g.copy vector="${FROM_POINT}",from_via_to_points --overwrite --quiet`)
        if (this.VIA === 0 || this.VIA === 1) {
            execSync(`grass "${GRASS}"/global/module_1 --exec v.patch input="${FROM_POINT}","${VIA_POINT}" output=from_via_to_points --overwrite --quiet`)
        }

        // # "TO" points are not optional. Optional only to place them on-by-one on the map, or  selecting an already existing map. If there are no user defined/selected to_points, default points (highway_points) are used as to_points. But, because these points are on the road by its origin, therefore no further connecting is requested.
        if (this.TO === 0 || this.TO === 1) {
            execSync(`grass "${GRASS}"/global/module_1 --exec v.patch input="${TO_POINT}","${FROM_POINT}","${VIA_POINT}" output=from_via_to_points --overwrite --quiet`)
        } else if (this.TO === 2) {
            execSync(`grass "${GRASS}"/global/module_1  --exec v.to.points input=highways output=highway_points dmax="${ROAD_POINTS}" --overwrite --quiet`)
            this.TO_POINT = "highway_points"
        }
        // threshold to connect is ~ 330 m
        execSync(`grass "${GRASS}"/global/module_1 --exec v.net input=highways points=from_via_to_points output=highways_points_connected operation=connect threshold="${CONNECT_DISTANCE}" --overwrite --quiet`)

        // Because of the previous operations, in many case, there is no more "highway" column. Now we have to rename a_highway to highway again.
        // But, in some cases -- because of the differences between country datasets -- highway field io not affected,
        // the original highway field remains the same. In this case it is not neccessary to rename it.
        let grep
        try {
            grep = execSync(`grass "${GRASS}"/global/module_1 --exec db.columns table=highways | grep a_highway`).toString()
        } catch (err) {
            console.log(err.message)
        }
        if (grep !== undefined) {
            execSync(`grass "${GRASS}"/global/module_1  --exec v.db.renamecolumn map=highways_points_connected column=a_highway,highway`)
        }

        //  Add "spd_average" attribute column (integer type) to the road network map (if not yet exist -- if exist Grass will skip this process)
        execSync(`grass "${GRASS}"/global/module_1 --exec v.db.addcolumn map=highways_points_connected columns='avg_speed INT'`)

        // Fill this new avg_speed column for each highway feature. Values are stored in $VARIABLES/roads_speed
        // 169 is the size of the file when only one digit is rendered to each line. Smaller values are not possible, since the minimal speed is only 0, not a negative number.
        // if [ $(echo $(stat --printf="%s" $VARIABLES/roads_speed)) -lt 169 -o ! -f $VARIABLES/roads_speed ]; then ##?##
        //     cp $VARIABLES/roads_speed_defaults $VARIABLES/roads_speed
        // fi
        if (fs.existsSync(`${VARIABLES}/roads_speed`) || parseInt(execSync(`echo $(stat --printf="%s" test.js)`).toString().trim()) > 169) {
            existsSync(`cp "${VARIABLES}"/roads_speed_defaults "${VARIABLES}"/roads_speed`)

        }

        // Now updating the datatable of highways_points_connected map, using "roads_speed" file to get speed data and conditions. limit is 9 -- until [ $n -gt 9 ]; do -- because the file $VARIABLES/roads_speed has 9 lines. When the number of lines changed in the file, limit value also has to be changed.
        for (let i = 0; i < 10; i++) {
            execSync(`grass "${GRASS}"/global/module_1 --exec v.db.update map=highways_points_connected layer=1 column=avg_speed value=$(cat "${VARIABLES}"/roads_speed | head -n$n | tail -n1 | cut -d":" -f2 | sed s'/ //'g) where="$(cat "${VARIABLES}"/highway_types | head -n$n | tail -n1)"`)
        }

        // Converting clipped and connected road network map into raster format and float number
        execSync(`grass "${GRASS}"/global/module_1  --exec v.to.rast input=highways_points_connected output=highways_points_connected use=attr attribute_column=avg_speed --overwrite --quiet`)
        execSync(`grass "${GRASS}"/global/module_1  --exec r.mapcalc expression="highways_points_connected=float(highways_points_connected)" --overwrite --quiet`)

        // Now vector zones are created around from, via and to points (its radius is equal to the curren resolution),
        // converted into raster format, and patched to raster map 'temp' (just created in the previous step)
        // zones:
        execSync(`grass "${GRASS}"/global/module_1 --exec v.buffer input=from_via_to_points output=from_via_to_zones distance=$(cat $VARIABLES/resolution | tail -n1) minordistance=$(cat $VARIABLES/resolution | tail -n1) --overwrite --quiet`)
        execSync(`grass "${GRASS}"/global/module_1 --exec r.mapcalc expression="from_via_to_zones=float(from_via_to_zones)" --overwrite --quiet`)
        execSync(`grass "${GRASS}"/global/module_1 --exec v.to.rast input=from_via_to_zones output=from_via_to_zones use=val val=$AVERAGE_SPEED --overwrite --quiet`)
        execSync(`grass "${GRASS}"/global/module_1 --exec r.patch input=highways_points_connected,from_via_to_zones output=highways_points_connected_zones --overwrite --quiet`)

        // Now the Supplementary lines (formerly CAT_SUPP_LINES) raster map have to be added to map highways_from_points. First I convert highways_points_connected into raster setting value to 0(zero). Resultant map: temp. After I patch temp and highways_points_connected, result is:highways_points_connected_temp. Now have to reclass highways_points_connected_temp, setting 0 values to the speed value of residentals
        execSync(`grass "${GRASS}"/global/module_1 --exec v.to.rast input=highways_points_connected output=temp use=val val="${AVERAGE_SPEED}" --overwrite --quiet`)
        execSync(`grass "${GRASS}"/global/module_1 --exec r.patch input=highways_points_connected_zones,temp output=highways_points_connected_temp --overwrite --quiet`)

        if (this.AREA === 0 || this.AREA === 1) {
            execSync(`grass "${GRASS}"/global/module_1 --exec v.to.rast input="${this.AREA_MAP}" output="${this.AREA_MAP}" use=val value="${this.REDUCING_RATIO}" --overwrite`)
            execSync(`grass "${GRASS}"/global/module_1 --exec r.null map="${this.AREA_MAP}"  null=1 --overwrite`)
            execSync(`grass "${GRASS}"/global/module_1 --exec r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*"${this.AREA_MAP}")" --overwrite --quiet`)
        }
        else if (this.AREA === 2) {
            execSync(`grass "${GRASS}"/global/module_1 --exec r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*1)" --overwrite --quiet`)
        }

        // specific_time here is the time requested to cross a cell, where the resolution is as defined in resolution file
        execSync(`grass "${GRASS}"/global/module_1 --exec r.mapcalc expression="specific_time=$(cat "${VARIABLES}"/resolution | head -n3 | tail -n1)/(highways_points_connected_full*0.27777)" --overwrite --quiet`)

        // Calculating from -- via time map, via -- to time map and it sum. There is a NULL value replacenet too. It is neccessary, because otherwise, if one of the maps containes NULL value, NULL value cells will not considering while summarizing the maps. Therefore, before mapcalc operation, NULL has to be replaced by 0.
        if (this.VIA === 0 || this.VIA === 1) {
            execSync(`grass "${GRASS}"/global/module_1 --exec r.cost input=specific_time output=from_via_cost start_points="${this.FROM_POINT}" stop_points="${this.VIA_POINT}" --overwrite --quiet`)
            execSync(`grass "${GRASS}"/global/module_1 --exec r.null map=from_via_cost null=0 --overwrite`)
            execSync(`grass "${GRASS}"/global/module_1 --exec r.cost input=specific_time output=via_to_cost start_points="${this.VIA_POINT}" stop_points="${this.TO_POINT}" --overwrite --quiet`)
            execSync(`grass "${GRASS}"/global/module_1 --exec r.null map=via_to_cost null=0 --overwrite`)
            execSync(`grass "${GRASS}"/global/module_1 --exec r.mapcalc expression="time_map_temp=from_via_cost+via_to_cost" --overwrite --quiet`)
            execSync(`grass "${GRASS}"/global/module_1 --exec r.mapcalc expression="time_map=time_map_temp/60" --overwrite --quiet`)
        } else {
            execSync(`grass "${GRASS}"/global/module_1 --exec r.cost input=specific_time output=from_to_cost start_points="${this.FROM_POINT}" stop_points="${this.TO_POINT}" --overwrite --quiet`)
            execSync(`grass "${GRASS}"/global/module_1 --exec r.mapcalc expression="time_map_temp=from_to_cost/60" --overwrite --quiet`)
            execSync(`grass "${GRASS}"/global/module_1 --exec g.rename raster=time_map_temp,m1_time_map --overwrite --quiet`)
        }

        execSync(`grass "${GRASS}"/global/module_1 --exec r.null map=m1_time_map setnull=0`)
        execSync(`grass "${GRASS}"/global/module_1 --exec r.out.gdal input=m1_time_map output="${GEOSERVER}"/m1_time_map.tif format=GTiff --overwrite --quiet`)

        // Interpolation for the entire area of selection map

        execSync(`grass "${GRASS}"/global/module_1 --exec g.region res="${BASE_RESOLUTION}" --overwrite`)
        execSync(`grass "${GRASS}"/global/module_1 --exec r.mask vector=selection --overwrite`)
        execSync(`grass "${GRASS}"/global/module_1 --exec v.db.addcolumn map=highway_points layer=2 columns="time DOUBLE PRECISION" --overwrite`)
        execSync(`grass "${GRASS}"/global/module_1 --exec v.what.rast map=highway_points@module_1 raster=m1_time_map layer=2 column=time --overwrite`)
        execSync(`grass "${GRASS}"/global/module_1 --exec v.surf.rst input=highway_points@module_1 layer=2 zcolumn=time where="time>0" elevation=m1_time_map_interpolated tension="${TENSION}" smooth="${SMOOTH}" nprocs=4 --overwrite`)
        execSync(`grass "${GRASS}"/global/module_1 --exec r.out.gdal input=m1_time_map_interpolated output="${GEOSERVER}"/m1_time_map_interpolated.tif format=GTiff --overwrite --quiet`)
        
        // set color for maps:
        execSync(`grass "${GRASS}"/global/module_1 --exec g.region res=$(cat "${VARIABLES}"/resolution)`)
        execSync(`r.colors -a map=m1_time_map color=gyr`) // ?
        execSync(`r.colors map=m1_time_map_interpolated color=gyr`) // ?
        
        /**
         * ##?## $MODULE
         */
        // echo "Map output for time map calculations" >$MODULE/temp_time_map_info_text
        // echo "" >>$MODULE/temp_time_map_info_text
        // echo "Date of map creation: $DATE_VALUE" >>$MODULE/temp_time_map_info_text
        // echo "" >>$MODULE/temp_time_map_info_text
        // echo "Colors on map represents time in minutes" >>$MODULE/temp_time_map_info_text
        // echo "Numbers of legend are time in minutes" >>$MODULE/temp_time_map_info_text
        // echo "" >>$MODULE/temp_time_map_info_text
        // echo "Start point: yellow cross" >>$MODULE/temp_time_map_info_text
        // echo "Via point: purple cross" >>$MODULE/temp_time_map_info_text
        // echo "Target point red cross" >>$MODULE/temp_time_map_info_text
        // echo "Stricken area: black line" >>$MODULE/temp_time_map_info_text
        // echo "" >>$MODULE/temp_time_map_info_text
        // echo "Considered speed on roads:" >>$MODULE/temp_time_map_info_text
        // cat $VARIABLES/roads_speed >>$MODULE/temp_time_map_info_text
        // echo "" >>$MODULE/temp_time_map_info_text
        // echo "Speed reduction coefficient for stricken area: $REDUCING_RATIO" >>$MODULE/temp_time_map_info_text
        
        // enscript -p $MODULE/temp_time_map_info_text.ps $MODULE/temp_time_map_info_text
        // ps2pdf $MODULE/temp_time_map_info_text.ps $MODULE/temp_time_map_info_text.pdf
        
        // grass $GRASS/$MAPSET --exec ps.map input=$MODULE/ps_param_1 output=$MODULE/time_map_1.ps --overwrite
        // grass $GRASS/$MAPSET --exec ps.map input=$MODULE/ps_param_2 output=$MODULE/time_map_2.ps --overwrite
        // ps2pdf $MODULE/time_map_1.ps $MODULE/time_map_1.pdf
        // ps2pdf $MODULE/time_map_2.ps $MODULE/time_map_2.pdf
        
        // gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=$MODULE/temp_m1_results_$DATE_VALUE_2".pdf" $MODULE/temp_time_map_info_text.pdf $MODULE/time_map_1.pdf $MODULE/time_map_2.pdf
        
        // mv $MODULE/temp_m1_results_$DATE_VALUE_2".pdf" ~/cityapp/saved_results/time_map_results_$DATE_VALUE_2".pdf"
    }
}

module.exports = ModuleOne
