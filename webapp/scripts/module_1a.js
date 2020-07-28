const fs = require('fs')
const { addVector, gpkgOut, initMapset, listVector, mapsetExists, grass, mergePDFs, psToPDF, textToPS } = require('./functions')

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GRASS = process.env.GRASS_DIR
const OUTPUT = process.env.OUTPUT_DIR

const AVERAGE_SPEED = 40
const ROAD_POINTS = 0.003
const CONNECT_DISTANCE = 0.003
const CONVERSION_RESOLUTION = 0.0001

class ModuleOneA {
  constructor() {
    this.messages = {
      1: {
        message_id: 'module_1a.1',
        message: { "text": "Start point is required. If you want to add a start point, draw one or more points and click 'Save'. To exit, click Cancel." }
      },
      2: {
        message_id: 'module_1a.2',
        message: { "text": "Via point is optional. If you want to add via points, draw one or more points and click 'Save'. If you do not want to add via points, click Cancel." }
      },
      3: {
        message_id: 'module_1a.3',
        message: { "text": "Stricken area is optional. If you want to add stricken area, draw one or more areas and click 'Save'. If you do not want to add stricken area, click Cancel." }
      },
      4: {
        message_id: 'module_1a.4',
        message: { "text": "Set speed reduction ratio (in percentage, without the % character) for roads of stricken area. Value has to be greater than 0 and less or equale to 100." }
      },
      5: {
        message_id: 'module_1a.5',
        message: { "text": "Process cancelled." }
      },
      6: {
        message_id: 'module_1a.6',
        message: { "text": "Calculations are ready, display output time maps." }
      },
      7: {
        message_id: 'module_1a.7',
        message: { "text": "No valid location found. Run \"Set new location\" to create a valid location. Module is now exiting." }
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
    if (!mapsetExists('PERMANENT')) {
      return this.messages[7]
    }

    initMapset('module_1')

    // Clip lines and polygons@PERMANENT mapset with the area_of_interest, defined by the user
    // Results will be stored in the "module_1" mapset
    grass('module_1', `g.copy vector=selection@PERMANENT,selection --overwrite`)
    grass('module_1', `g.copy vector=lines@PERMANENT,lines --overwrite`)

    this.vectorMaps = listVector('module_1')

    this.resolution = parseFloat(fs.readFileSync(`${GRASS}/variables/resolution`).toString().trim().split('\n')[1])

    if (!fs.existsSync(`${GRASS}/variables/roads_speed`)) {
      fs.copyFileSync(`${GRASS}/variables/defaults/roads_speed_defaults`, `${GRASS}/variables/roads_speed`)
    }
    this.roadsSpeed = fs.readFileSync(`${GRASS}/variables/roads_speed`).toString().trim().split('\n')
    this.highwayTypes = fs.readFileSync(`${GRASS}/variables/defaults/highway_types`).toString().trim().split('\n')
    this.roadSpeedValues = new Map(this.highwayTypes.map((t, i) => [t, parseInt(this.roadsSpeed[i].split(':')[1])]))

    // Creating empty maps for ps output, if no related maps are created/selected by user:
    // m1_via_points m1_to_points, m1_stricken_area
    // If user would create a such map, empty maps will automatically overwritten
    grass('module_1', `v.edit map=m1_via_points tool=create --overwrite`)
    grass('module_1', `v.edit map=m1_to_points tool=create --overwrite`)
    grass('module_1', `v.edit map=m1_stricken_area tool=create --overwrite`)

    return this.messages[1]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'module_1a.1':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_1', message, 'm1_from_points')
          gpkgOut('module_1', 'm1_from_points', 'm1_from_points')
          this.fromPoints = 'm1_from_points'
          return this.messages[2]
        }
        return this.messages[5]

      case 'module_1a.2':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_1', message, 'm1_via_points')
          gpkgOut('module_1', 'm1_via_points', 'm1_via_points')
          this.viaPoints = 'm1_via_points'
          return this.messages[3]
        }
        return this.messages[3]

      case 'module_1a.3':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_1', message, 'm1_stricken_area')
          gpkgOut('module_1', 'm1_stricken_area', 'm1_stricken_area')
          this.strickenArea = 'm1_stricken_area'
          return this.messages[4]
        }
        return this.messages[4]

      case 'module_1a.4':
        this.reductionRatio = parseFloat(message)
        this.calculate()
        return this.messages[6]
    }
  }

  calculate() {
    console.log("Calculating time maps …")

    // Creating highways map. This is fundamental for the further work in this module
    grass('module_1', `v.extract input=lines@PERMANENT type=line where="highway>0" output=highways --overwrite`)

    // Setting region to fit the "selection" map (taken by location_selector) and resolution
    grass('module_1', `g.region vector=selection@PERMANENT res=${this.resolution} --overwrite`)

    // connecting from/via/to points to the clipped network, if neccessary. Via points are optional, first have to check if user previously has selected those or not.
    grass('module_1', `g.copy vector=${this.fromPoints},from_via_to_points --overwrite`)
    if (this.viaPoints) {
      grass('module_1', `v.patch input=${this.fromPoints},${this.viaPoints} output=from_via_to_points --overwrite`)
    }

    // "TO" points has a default value, the points of the road network will used for. But, because these points are on the road by its origin, therefore no further connecting is requested.
    grass('module_1', `v.to.points input=highways output=highway_points dmax=${ROAD_POINTS} --overwrite`)
    this.toPoints = 'highway_points'

    // # threshold to connect is ~ 330 m
    grass('module_1', `v.net input=highways points=from_via_to_points output=highways_points_connected operation=connect threshold=${CONNECT_DISTANCE} --overwrite`)

    // Because of the previous operations, in many case, there is no more "highway" column. Now we have to rename a_highway to highway again.
    // But, in some cases -- because of the differences between country datasets -- highway field io not affected,
    // the original highway field remains the same. In this case it is not neccessary to rename it.
    let columns = grass('module_1', `db.columns table=highways`).trim()
    if (columns.split('\n').indexOf('a_highway') > -1) {
      grass('module_1', `v.db.renamecolumn map=highways_points_connected column=a_highway,highway`)
    }

    // Add "spd_average" attribute column (integer type) to the road network map (if not yet exist -- if exist Grass will skip this process)
    grass('module_1', `v.db.addcolumn map=highways_points_connected columns='avg_speed INT'`)

    // Now updating the datatable of highways_points_connected map, using "roads_speed" file to get speed data and conditions.
    for (const [where, value] of this.roadSpeedValues) {
      grass('module_1', `v.db.update map=highways_points_connected layer=1 column=avg_speed value=${value} where="${where.replace(/"/g, '\\"')}"`)
    }

    // Converting clipped and connected road network map into raster format and float number
    grass('module_1', `v.to.rast input=highways_points_connected output=highways_points_connected use=attr attribute_column=avg_speed --overwrite`)
    grass('module_1', `r.mapcalc expression="highways_points_connected=float(highways_points_connected)" --overwrite`)

    // Now vector zones are created around from, via and to points (its radius is equal to the curren resolution),
    // converted into raster format, and patched to raster map 'temp' (just created in the previous step)
    grass('module_1', `v.buffer input=from_via_to_points output=from_via_to_zones distance=${this.resolution} minordistance=${this.resolution} --overwrite`)
    grass('module_1', `r.mapcalc expression="from_via_to_zones=float(from_via_to_zones)" --overwrite`)
    grass('module_1', `v.to.rast input=from_via_to_zones output=from_via_to_zones use=val val=${AVERAGE_SPEED} --overwrite`)
    grass('module_1', `r.patch input=highways_points_connected,from_via_to_zones output=highways_points_connected_zones --overwrite`)

    // Now the Supplementary lines (formerly CAT_SUPP_LINES) raster map have to be added to map highways_from_points. First I convert highways_points_connected into raster setting value to 0(zero). Resultant map: temp. After I patch temp and highways_points_connected, result is:highways_points_connected_temp. Now have to reclass highways_points_connected_temp, setting 0 values to the speed value of residentals
    grass('module_1', `v.to.rast input=highways_points_connected output=temp use=val val=${AVERAGE_SPEED} --overwrite`)
    grass('module_1', `r.patch input=highways_points_connected_zones,temp output=highways_points_connected_temp --overwrite`)

    if (this.strickenArea) {
      grass('module_1', `v.to.rast input=${this.strickenArea} output=${this.strickenArea} use=val value=${this.reductionRatio} --overwrite`)
      grass('module_1', `r.null map="${this.strickenArea} null=1 --overwrite`)
      grass('module_1', `r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*${this.strickenArea})" --overwrite`)
    } else {
      grass('module_1', `r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*1)" --overwrite`)
    }

    // specific_time here is the time requested to cross a cell, where the resolution is as defined in resolution file
    grass('module_1', `r.mapcalc expression="specific_time=${this.resolution}/(highways_points_connected_full*0.27777)" --overwrite`)

    // Calculating from -- via time map, via -- to time map and it sum. There is a NULL value replacenet too. It is neccessary, because otherwise, if one of the maps containes NULL value, NULL value cells will not considering while summarizing the maps. Therefore, before mapcalc operation, NULL has to be replaced by 0.
    if (this.viaPoints) {
      grass('module_1', `r.cost input=specific_time output=from_via_cost start_points=${this.fromPoints} stop_points=${this.viaPoints} --overwrite`)
      grass('module_1', `r.null map=from_via_cost null=0 --overwrite`)
      grass('module_1', `r.cost input=specific_time output=via_to_cost start_points=${this.viaPoints} stop_points=${this.toPoints} --overwrite`)
      grass('module_1', `r.null map=via_to_cost null=0 --overwrite`)
      grass('module_1', `r.mapcalc expression="time_map_temp=from_via_cost+via_to_cost" --overwrite`)
      grass('module_1', `r.mapcalc expression="time_map=time_map_temp/60" --overwrite`)
    } else {
      grass('module_1', `r.cost input=specific_time output=from_to_cost start_points=${this.fromPoints} stop_points=${this.toPoints} --overwrite`)
      grass('module_1', `r.mapcalc expression="time_map_temp=from_to_cost/60" --overwrite`)
      grass('module_1', `g.rename raster=time_map_temp,m1_time_map --overwrite`)
    }

    // Converting the result into vector point format
    grass('module_1', `g.region res=${CONVERSION_RESOLUTION}`)
    grass('module_1', `r.to.vect input=m1_time_map output=m1_time_map type=point column=data --overwrite`)
    grass('module_1', `v.out.ogr -s input=m1_time_map@module_1 type=point output="${GEOSERVER}/m1_time_map.gpkg" --overwrite`)

    // Generating pdf output

    // stricken area will used as a line string, therefore first convert from area to line (ps_param_1 and psparam_2 refers to a line map):
    grass('module_1', `v.type input=m1_stricken_area output=m1_stricken_area_line from_type=boundary to_type=line --overwrite`)

    // set color for maps:
    grass('module_1', `g.region res=${this.resolution}`)
    grass('module_1', `r.colors -a map=m1_time_map color=gyr`)

    const date = new Date()
    const dateString = date.toString()
    const safeDateString = date.toISOString().replace(/([\d-]*)T(\d\d):(\d\d):[\d.]*Z/g, '$1_$2$3')

    fs.mkdirSync('tmp', { recursive: true })
    fs.writeFileSync('tmp/time_map_info_text', `
Map output for time map calculations

Date of map creation: ${dateString}

Colors on map represents time in minutes
Numbers of legend are time in minutes

Start point: yellow cross
Via point: purple cross
Target point: red cross
Stricken area: black line

Considered speed on roads:
${this.roadsSpeed.join('\n')}

Speed reduction coefficient for stricken area: ${this.reductionRatio}`)

    textToPS('tmp/time_map_info_text', 'tmp/time_map_info_text.ps')
    psToPDF('tmp/time_map_info_text.ps', 'tmp/time_map_info_text.pdf')

    grass('module_1', `ps.map input="${GRASS}/variables/defaults/module_1a.ps_param_1" output=tmp/time_map_1.ps --overwrite`)
    psToPDF('tmp/time_map_1.ps', 'tmp/time_map_1.pdf')

    mergePDFs(`${OUTPUT}/time_map_results_${safeDateString}.pdf`, 'tmp/time_map_info_text.pdf', 'tmp/time_map_1.pdf')

    fs.rmdirSync('tmp', { recursive: true })
  }
}

module.exports = ModuleOneA
