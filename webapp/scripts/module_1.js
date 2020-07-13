const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html
const fs = require('fs')

const { addVector, gpkgOut, listVector, mapsetExists } = require('./functions')

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GRASS = process.env.GRASS_DIR

const ROAD_POINTS = 0.003
const CONNECT_DISTANCE = 0.003
const AVERAGE_SPEED = 40
const BASE_RESOLUTION = 0.0005
const SMOOTH = 4
const TENSION = 30

class ModuleOne {
  constructor() {
    this.messages = {
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
        message: { "text": "Select a map (only point maps are supported). Avilable maps are:" }
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
        message: { "text": "Do you want to set the speed on the road network? If not, the current values will used." }
      },
      10: {
        message_id: 'module_1.10',
        message: { "text": "Now you can change the speed values. Current values are:" }
      },
      11: {
        message_id: 'module_1.11',
        message: { "text": "No valid location found. Run Location selector to create a valid location. Module is now exiting." }
      },
      12: {
        message_id: 'module_1.12',
        message: { "text": "Set speed reduction ratio for roads of stricken area. This must be a number greater than 0 and less than 1." }
      },
      14: {
        message_id: 'module_1.14',
        message: { "text": "Calculations are ready, display output time maps" }
      }
    }
    this.fromPoints = ''
    this.viaPoints = ''
    this.toPoints = ''
    this.strickenArea = ''
    this.reductionRatio = null // Speed reduction ratio for roads of stricken area
    this.roadsSpeed = null
  }

  launch() {
    if (!fs.existsSync(`${GRASS}/global/module_1`)) {
      fs.mkdirSync(`${GRASS}/global/module_1`)
    }
    fs.copyFileSync(`${GRASS}/global/PERMANENT/WIND`, `${GRASS}/global/module_1/WIND`)
    // FIXME: do we need "skel"?
    // for (const file of fs.readdirSync(`${GRASS}/skel`)) {
    //   fs.copyFileSync(`${GRASS}/skel/${file}`, `${GRASS}/global/module_1/${file}`)
    // }

    this.vectorMaps = listVector('module_1')

    this.resolution = fs.readFileSync(`${GRASS}/variables/resolution`).toString().trim().split('\n')[1]
    this.roadsSpeed = fs.readFileSync(`${GRASS}/variables/roads_speed`).toString().trim().split('\n')
    this.highwayTypes = fs.readFileSync(`${GRASS}/variables/defaults/highway_types`).toString().trim().split('\n')
    this.roadSpeedValues = new Map(this.highwayTypes.map((t, i) => [t, parseInt(this.roadsSpeed[i].split(':')[1])]))

    if (mapsetExists('PERMANENT')) {
      return this.messages[1]
    }
    return this.messages[11]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'module_1.1':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_1', message, 'm1_from_points')
          gpkgOut('module_1', 'm1_from_points', 'm1_from_points')
          this.fromPoints = 'm1_from_points'
          return this.messages[3]
        } else if (message.toLowerCase() == 'no') {
          const msg = this.messages[2]
          msg.message.list = this.vectorMaps
          return msg
        }
        return

      case 'module_1.2':
        this.fromPoints = message
        return this.messages[3]

      case 'module_1.3':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_1', message, 'm1_via_points')
          gpkgOut('module_1', 'm1_via_points', 'm1_via_points')
          this.viaPoints = 'm1_via_points'
          return this.messages[5]
        } else if (message.toLowerCase() == 'no') {
          const msg = this.messages[4]
          msg.message.list = this.vectorMaps
          return msg
        }
        return this.messages[5]

      case 'module_1.4':
        this.viaPoints = message
        return this.messages[5]

      case 'module_1.5':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_1', message, 'm1_to_points')
          gpkgOut('module_1', 'm1_to_points', 'm1_to_points')
          this.toPoints = 'm1_to_points'
          return this.messages[7]
        } else if (message.toLowerCase() == 'no') {
          const msg = this.messages[6]
          msg.message.list = this.vectorMaps
          return msg
        }
        return this.messages[7]

      case 'module_1.6':
        this.toPoints = message
        return this.messages[7]

      case 'module_1.7':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_1', message, 'm1_stricken_area')
          gpkgOut('module_1', 'm1_stricken_area', 'm1_stricken_area')
          this.strickenArea = 'm1_stricken_area'
          return this.messages[12]
        } else if (message.toLowerCase() == 'no') {
          return this.messages[8]
        }
        return this.messages[12]

      case 'module_1.8':
        this.strickenArea = message
        return this.messages[9]

      case 'module_1.12':
        this.reductionRatio = message
        return this.messages[9]

      case 'module_1.9':
        if (message.toLowerCase() == 'yes') {
          return this.messages[10]
        }
        else if (message.toLowerCase() == 'no') {
          this.calculate()
          return this.messages[14]
        }
        return

      case 'module_1.11':
        this.roadsSpeed = message // not used
        this.calculate()
        return this.messages[14]
    }
  }

  calculate() {
    // Creating highways map. This is fundamental for the further work in this module
    // FIXME: errors if lines@PERMANENT is missing or not covering the desired location
    execSync(`grass "${GRASS}/global/module_1" --exec v.extract input=lines@PERMANENT type=line where="highway>0" output=highways --overwrite --quiet`)
    // True data processing Setting region to fit the "selection" map (taken by location_selector), and resolution
    execSync(`grass "${GRASS}/global/module_1" --exec g.region vector=selection@PERMANENT res="${this.resolution}" --overwrite`)

    // connecting from/via/to points to the clipped network, if neccessary. Via points are optional, first have to check if user previously has selected those or not.
    execSync(`grass "${GRASS}/global/module_1" --exec g.copy vector="${this.fromPoints},from_via_to_points" --overwrite --quiet`)
    if (this.viaPoints) {
      execSync(`grass "${GRASS}/global/module_1" --exec v.patch input="${this.fromPoints},${this.viaPoints}" output=from_via_to_points --overwrite --quiet`)
    }

    // "TO" points are not optional. Optional only to place them one-by-one on the map, or selecting an already existing map. If there are no user defined/selected to_points, default points (highway_points) are used as to_points. But, because these points are on the road by its origin, therefore no further connecting is requested.
    if (this.toPoints) {
      execSync(`grass "${GRASS}/global/module_1" --exec v.patch input="${this.toPoints},${this.fromPoints},${this.viaPoints}" output=from_via_to_points --overwrite --quiet`)
    } else {
      execSync(`grass "${GRASS}/global/module_1" --exec v.to.points input=highways output=highway_points dmax="${ROAD_POINTS}" --overwrite --quiet`)
      this.toPoints = "highway_points"
    }
    // threshold to connect is ~ 330 m
    execSync(`grass "${GRASS}/global/module_1" --exec v.net input=highways points=from_via_to_points output=highways_points_connected operation=connect threshold="${CONNECT_DISTANCE}" --overwrite --quiet`)

    // Because of the previous operations, in many case, there is no more "highway" column. Now we have to rename a_highway to highway again.
    // But, in some cases -- because of the differences between country datasets -- highway field io not affected,
    // the original highway field remains the same. In this case it is not neccessary to rename it.
    let columns = execSync(`grass "${GRASS}/global/module_1" --exec db.columns table=highways`).toString().trim()
    if (columns.split('\n').indexOf('a_highway') > -1) {
      execSync(`grass "${GRASS}/global/module_1" --exec v.db.renamecolumn map=highways_points_connected column=a_highway,highway`)
    }

    //  Add "spd_average" attribute column (integer type) to the road network map (if not yet exist -- if exist Grass will skip this process)
    execSync(`grass "${GRASS}/global/module_1" --exec v.db.addcolumn map=highways_points_connected columns='avg_speed INT'`)

    // Fill this new avg_speed column for each highway feature. Values are stored in $VARIABLES/roads_speed
    if (!fs.existsSync(`${GRASS}/variables/roads_speed`)) {
      fs.copyFileSync(`${GRASS}/variables/defaults/roads_speed_defaults`, `${GRASS}/variables/roads_speed`)
    }

    // Now updating the datatable of highways_points_connected map, using "roads_speed" file to get speed data and conditions.
    for (const [where, value] of this.roadSpeedValues) {
      execSync(`grass "${GRASS}/global/module_1" --exec v.db.update map=highways_points_connected layer=1 column=avg_speed value=${value} where="${where.replace(/"/g, '\\"')}"`)
    }

    // Converting clipped and connected road network map into raster format and float number
    execSync(`grass "${GRASS}/global/module_1" --exec v.to.rast input=highways_points_connected output=highways_points_connected use=attr attribute_column=avg_speed --overwrite --quiet`)
    execSync(`grass "${GRASS}/global/module_1" --exec r.mapcalc expression="highways_points_connected=float(highways_points_connected)" --overwrite --quiet`)

    // Now vector zones are created around from, via and to points (its radius is equal to the current resolution),
    // converted into raster format, and patched to raster map 'temp' (just created in the previous step)
    execSync(`grass "${GRASS}/global/module_1" --exec v.buffer input=from_via_to_points output=from_via_to_zones distance="${this.resolution}" minordistance="${this.resolution}" --overwrite --quiet`)
    execSync(`grass "${GRASS}/global/module_1" --exec r.mapcalc expression="from_via_to_zones=float(from_via_to_zones)" --overwrite --quiet`)
    execSync(`grass "${GRASS}/global/module_1" --exec v.to.rast input=from_via_to_zones output=from_via_to_zones use=val val="${AVERAGE_SPEED}" --overwrite --quiet`)
    execSync(`grass "${GRASS}/global/module_1" --exec r.patch input=highways_points_connected,from_via_to_zones output=highways_points_connected_zones --overwrite --quiet`)

    // Now the Supplementary lines (formerly CAT_SUPP_LINES) raster map have to be added to map highways_from_points. First I convert highways_points_connected into raster setting value to 0(zero). Resultant map: temp. After I patch temp and highways_points_connected, result is:highways_points_connected_temp. Now have to reclass highways_points_connected_temp, setting 0 values to the speed value of residentals
    execSync(`grass "${GRASS}/global/module_1" --exec v.to.rast input=highways_points_connected output=temp use=val val="${AVERAGE_SPEED}" --overwrite --quiet`)
    execSync(`grass "${GRASS}/global/module_1" --exec r.patch input=highways_points_connected_zones,temp output=highways_points_connected_temp --overwrite --quiet`)

    if (this.strickenArea) {
      execSync(`grass "${GRASS}/global/module_1" --exec v.to.rast input="${this.strickenArea}" output="${this.strickenArea}" use=val value="${this.reductionRatio}" --overwrite`)
      execSync(`grass "${GRASS}/global/module_1" --exec r.null map="${this.strickenArea}"  null=1 --overwrite`)
      execSync(`grass "${GRASS}/global/module_1" --exec r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*${this.strickenArea})" --overwrite --quiet`)
    } else {
      execSync(`grass "${GRASS}/global/module_1" --exec r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*1)" --overwrite --quiet`)
    }

    // specific_time here is the time required to cross a cell, where the resolution is as defined in resolution file
    execSync(`grass "${GRASS}/global/module_1" --exec r.mapcalc expression="specific_time=${this.resolution}/(highways_points_connected_full*0.27777)" --overwrite --quiet`)

    // Calculating from -- via time map, via -- to time map and it sum. There is a NULL value replacenet too. It is neccessary, because otherwise, if one of the maps containes NULL value, NULL value cells will not considering while summarizing the maps. Therefore, before mapcalc operation, NULL has to be replaced by 0.
    if (this.viaPoints) {
      execSync(`grass "${GRASS}/global/module_1" --exec r.cost input=specific_time output=from_via_cost start_points="${this.fromPoints}" stop_points="${this.viaPoints}" --overwrite --quiet`)
      execSync(`grass "${GRASS}/global/module_1" --exec r.null map=from_via_cost null=0 --overwrite`)
      execSync(`grass "${GRASS}/global/module_1" --exec r.cost input=specific_time output=via_to_cost start_points="${this.viaPoints}" stop_points="${this.toPoints}" --overwrite --quiet`)
      execSync(`grass "${GRASS}/global/module_1" --exec r.null map=via_to_cost null=0 --overwrite`)
      execSync(`grass "${GRASS}/global/module_1" --exec r.mapcalc expression="time_map_temp=from_via_cost+via_to_cost" --overwrite --quiet`)
      execSync(`grass "${GRASS}/global/module_1" --exec r.mapcalc expression="time_map=time_map_temp/60" --overwrite --quiet`)
    } else {
      execSync(`grass "${GRASS}/global/module_1" --exec r.cost input=specific_time output=from_to_cost start_points="${this.fromPoints}" stop_points="${this.toPoints}" --overwrite --quiet`)
      execSync(`grass "${GRASS}/global/module_1" --exec r.mapcalc expression="time_map_temp=from_to_cost/60" --overwrite --quiet`)
      execSync(`grass "${GRASS}/global/module_1" --exec g.rename raster=time_map_temp,m1_time_map --overwrite --quiet`)
    }

    execSync(`grass "${GRASS}/global/module_1" --exec r.null map=m1_time_map setnull=0`)
    execSync(`grass "${GRASS}/global/module_1" --exec r.out.gdal input=m1_time_map output="${GEOSERVER}/m1_time_map.tif" format=GTiff --overwrite --quiet`)

    // Interpolation for the entire area of selection map

    execSync(`grass "${GRASS}/global/module_1" --exec g.region res="${BASE_RESOLUTION}" --overwrite`)
    execSync(`grass "${GRASS}/global/module_1" --exec r.mask vector=selection --overwrite`)
    execSync(`grass "${GRASS}/global/module_1" --exec v.db.addcolumn map=highway_points layer=2 columns="time DOUBLE PRECISION" --overwrite`)
    execSync(`grass "${GRASS}/global/module_1" --exec v.what.rast map=highway_points@module_1 raster=m1_time_map layer=2 column=time --overwrite`)
    execSync(`grass "${GRASS}/global/module_1" --exec v.surf.rst input=highway_points@module_1 layer=2 zcolumn=time where="time>0" elevation=m1_time_map_interpolated tension="${TENSION}" smooth="${SMOOTH}" nprocs=4 --overwrite`)
    execSync(`grass "${GRASS}/global/module_1" --exec r.out.gdal input=m1_time_map_interpolated output="${GEOSERVER}/m1_time_map_interpolated.tif" format=GTiff --overwrite --quiet`)

    // set color for maps:
    execSync(`grass "${GRASS}/global/module_1" --exec g.region res="${this.resolution}"`)
    // execSync(`r.colors -a map=m1_time_map color=gyr`) // ?
    // execSync(`r.colors map=m1_time_map_interpolated color=gyr`) // ?

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
