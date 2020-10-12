const fs = require('fs')
const { addVector, checkWritableDir, gpkgOut, initMapset, listVector, mapsetExists, grass, mergePDFs, psToPDF, textToPS } = require('./functions')

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GRASS = process.env.GRASS_DIR
const OUTPUT = process.env.OUTPUT_DIR

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
        message: { "text": "Select a map (only point maps are supported). Available maps are:" }
      },
      3: {
        message_id: 'module_1.3',
        message: { "text": "Via points are optional. If you want to select via points from the map, click Yes. If you want to use an already existing map, select No. If you do not want to use via points, click Cancel." }
      },
      4: {
        message_id: 'module_1.4',
        message: { "text": "Select a map (only point maps are supported). Available maps are:" }
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
        message: { "text": "Optionally you may define a stricken area. If you want to draw an area on the map, click Yes. If you want to select a map containing an area, click No. If you do not want to use any area, click Cancel." }
      },
      8: {
        message_id: 'module_1.8',
        message: { "text": "Select a map (only area maps are supported)" }
      },
      9: {
        message_id: 'module_1.9',
        message: { "text": "Do you want to set the speed on the road network? If not, the current values will be used." }
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
    checkWritableDir(GEOSERVER)
    checkWritableDir(OUTPUT)

    if (!mapsetExists('PERMANENT')) {
      return this.messages[11]
    }

    initMapset('module_1')

    // Clip lines and polygons@PERMANENT mapset with the area_of_interest, defined by the user
    // Results will be stored in the "module_1" mapset
    grass('module_1', `g.copy vector=selection@PERMANENT,selection --overwrite`)
    grass('module_1', `g.copy vector=lines@PERMANENT,lines --overwrite`)

    this.vectorMaps = listVector('module_1')

    this.resolution = parseFloat(fs.readFileSync(`${GRASS}/variables/resolution`).toString().trim().split('\n')[1])
    this.roadsSpeed = fs.readFileSync(`${GRASS}/variables/roads_speed`).toString().trim().split('\n')
    this.highwayTypes = fs.readFileSync(`${GRASS}/variables/defaults/highway_types`).toString().trim().split('\n')
    this.roadSpeedValues = new Map(this.highwayTypes.map((t, i) => [t, parseInt(this.roadsSpeed[i].split(':')[1])]))

    return this.messages[1]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'module_1.1':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_1', message, 'm1_from_points')
          gpkgOut('module_1', 'm1_from_points', `${GEOSERVER}/m1_from_points.gpkg`)
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
          gpkgOut('module_1', 'm1_via_points', `${GEOSERVER}/m1_via_points.gpkg`)
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
          gpkgOut('module_1', 'm1_to_points', `${GEOSERVER}/m1_to_points.gpkg`)
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
          gpkgOut('module_1', 'm1_stricken_area', `${GEOSERVER}/m1_stricken_area.gpkg`)
          this.strickenArea = 'm1_stricken_area'
          return this.messages[12]
        } else if (message.toLowerCase() == 'no') {
          return this.messages[8]
        }
        return this.messages[9]

      case 'module_1.8':
        this.strickenArea = message
        return this.messages[12]

      case 'module_1.12':
        this.reductionRatio = parseFloat(message)
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

      // FIXME allow user to set speeds
      case 'module_1.10':
        this.roadsSpeed = message
        this.calculate()
        return this.messages[14]
    }
  }

  calculate() {
    console.log("Calculating time maps …")

    // Creating highways map. This is fundamental for the further work in this module
    // FIXME: errors if lines@PERMANENT is missing or not covering the desired location
    grass('module_1', `v.extract input=lines@PERMANENT type=line where="highway>0" output=highways --overwrite`)
    // True data processing Setting region to fit the "selection" map (taken by location_selector), and resolution
    grass('module_1', `g.region vector=selection@PERMANENT res=${this.resolution} --overwrite`)

    // connecting from/via/to points to the clipped network, if neccessary. Via points are optional, first have to check if user previously has selected those or not.
    grass('module_1', `g.copy vector="${this.fromPoints},from_via_to_points" --overwrite`)
    if (this.viaPoints) {
      grass('module_1', `v.patch input="${this.fromPoints},${this.viaPoints}" output=from_via_to_points --overwrite`)
    }

    // "TO" points are not optional. Optional only to place them one-by-one on the map, or selecting an already existing map. If there are no user defined/selected to_points, default points (highway_points) are used as to_points. But, because these points are on the road by its origin, therefore no further connecting is requested.
    if (this.toPoints) {
      grass('module_1', `v.patch input="${this.toPoints},${this.fromPoints},${this.viaPoints}" output=from_via_to_points --overwrite`)
    } else {
      grass('module_1', `v.to.points input=highways output=highway_points dmax=${ROAD_POINTS} --overwrite`)
      this.toPoints = 'highway_points'
    }

    // Build the network; threshold to connect is ~ 330 m
    grass('module_1', `v.net input=highways points=from_via_to_points output=highways_points_connected operation=connect threshold=${CONNECT_DISTANCE} --overwrite`)

    // Because of the previous operations, in many cases, there is no more "highway" column. Now we have to rename a_highway to highway again.
    // But, in some cases -- because of the differences between country datasets -- highway field is not affected,
    // the original highway field remains the same. In this case it is not neccessary to rename it.
    let columns = grass('module_1', `db.columns table=highways`).trim()
    if (columns.split('\n').indexOf('a_highway') > -1) {
      grass('module_1', `v.db.renamecolumn map=highways_points_connected column=a_highway,highway`)
    }

    //  Add "avg_speed" attribute column (integer) to the road network map (if not yet exist -- if exist Grass will skip this process)
    grass('module_1', `v.db.addcolumn map=highways_points_connected columns='avg_speed INT'`)

    // Fill this new avg_speed column for each highway feature. Values are stored in $VARIABLES/roads_speed
    if (!fs.existsSync(`${GRASS}/variables/roads_speed`)) {
      fs.copyFileSync(`${GRASS}/variables/defaults/roads_speed_defaults`, `${GRASS}/variables/roads_speed`)
    }

    // Now update the datatable of highways_points_connected map, using "roads_speed" file to get speed data and conditions.
    for (const [where, value] of this.roadSpeedValues) {
      grass('module_1', `v.db.update map=highways_points_connected layer=1 column=avg_speed value=${value} where="${where.replace(/"/g, '\\"')}"`)
    }

    // Converting clipped and connected road network map into raster format and float number
    grass('module_1', `v.to.rast input=highways_points_connected output=highways_points_connected use=attr attribute_column=avg_speed --overwrite`)
    grass('module_1', `r.mapcalc expression="highways_points_connected=float(highways_points_connected)" --overwrite`)

    // Now vector zones are created around from, via and to points (its radius is equal to the current resolution),
    // converted into raster format, and patched to raster map 'temp' (just created in the previous step)
    grass('module_1', `v.buffer input=from_via_to_points output=from_via_to_zones distance=${this.resolution} minordistance=${this.resolution} --overwrite`)
    // FIXME: there is a bug with this command
    // grass('module_1', `r.mapcalc expression="from_via_to_zones=float(from_via_to_zones)" --overwrite`)
    grass('module_1', `v.to.rast input=from_via_to_zones output=from_via_to_zones use=val val=${AVERAGE_SPEED} --overwrite`)
    grass('module_1', `r.patch input=highways_points_connected,from_via_to_zones output=highways_points_connected_zones --overwrite`)

    // Now the supplementary lines raster map has to be added to map highways_from_points. First we convert highways_points_connected into raster setting value to 0(zero), resulting in: temp. Then we patch temp and highways_points_connected, resulting in: highways_points_connected_temp. Now we have to reclass highways_points_connected_temp, setting 0 values to the speed value of residentals
    grass('module_1', `v.to.rast input=highways_points_connected output=temp use=val val=${AVERAGE_SPEED} --overwrite`)
    grass('module_1', `r.patch input=highways_points_connected_zones,temp output=highways_points_connected_temp --overwrite`)

    if (this.strickenArea) {
      grass('module_1', `v.to.rast input="${this.strickenArea}" output="${this.strickenArea}" use=val value=${this.reductionRatio} --overwrite`)
      grass('module_1', `r.null map="${this.strickenArea}" null=1 --overwrite`)
      grass('module_1', `r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*${this.strickenArea})" --overwrite`)
    } else {
      grass('module_1', `r.mapcalc expression="highways_points_connected_full=(highways_points_connected_temp*1)" --overwrite`)
    }

    // specific_time here is the time required to cross a cell, where the resolution is as defined in resolution file
    grass('module_1', `r.mapcalc expression="specific_time=${this.resolution}/(highways_points_connected_full*0.27777)" --overwrite`)

    // Calculating from -- via time map, via -- to time map and it sum. There is a NULL value replacenet too. It is neccessary, because otherwise, if one of the maps containes NULL value, NULL value cells will not considering while summarizing the maps. Therefore, before mapcalc operation, NULL has to be replaced by 0.
    if (this.viaPoints) {
      grass('module_1', `r.cost input=specific_time output=from_via_cost start_points="${this.fromPoints}" stop_points="${this.viaPoints}" --overwrite`)
      grass('module_1', `r.null map=from_via_cost null=0 --overwrite`)
      grass('module_1', `r.cost input=specific_time output=via_to_cost start_points="${this.viaPoints}" stop_points="${this.toPoints}" --overwrite`)
      grass('module_1', `r.null map=via_to_cost null=0 --overwrite`)
      grass('module_1', `r.mapcalc expression="time_map_temp=from_via_cost+via_to_cost" --overwrite`)
      grass('module_1', `r.mapcalc expression="time_map=time_map_temp/60" --overwrite`)
    } else {
      grass('module_1', `r.cost input=specific_time output=from_to_cost start_points="${this.fromPoints}" stop_points="${this.toPoints}" --overwrite`)
      grass('module_1', `r.mapcalc expression="time_map_temp=from_to_cost/60" --overwrite`)
      grass('module_1', `g.rename raster=time_map_temp,m1_time_map --overwrite`)
    }

    grass('module_1', `r.null map=m1_time_map setnull=0`)
    grass('module_1', `r.out.gdal input=m1_time_map output="${GEOSERVER}/m1_time_map.tif" format=GTiff --overwrite`)

    // Interpolation for the entire area of selection map
    grass('module_1', `g.region res=${BASE_RESOLUTION} --overwrite`)
    grass('module_1', `r.mask vector=selection --overwrite`)
    grass('module_1', `v.db.addcolumn map=highway_points layer=2 columns="time DOUBLE PRECISION" --overwrite`)
    grass('module_1', `v.what.rast map=highway_points@module_1 raster=m1_time_map layer=2 column=time --overwrite`)
    grass('module_1', `v.surf.rst input=highway_points@module_1 layer=2 zcolumn=time where="time>0" elevation=m1_time_map_interpolated tension=${TENSION} smooth=${SMOOTH} nprocs=4 --overwrite`)
    grass('module_1', `r.out.gdal input=m1_time_map_interpolated output="${GEOSERVER}/m1_time_map_interpolated.tif" format=GTiff --overwrite`)

    // Generate pdf output

    // set color for maps
    grass('module_1', `g.region res="${this.resolution}"`)

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

    grass('module_1', `ps.map input="${GRASS}/variables/defaults/module_1.ps_param_1" output=tmp/time_map_1.ps --overwrite`)
    grass('module_1', `ps.map input="${GRASS}/variables/defaults/module_1.ps_param_2" output=tmp/time_map_2.ps --overwrite`)
    psToPDF('tmp/time_map_1.ps', 'tmp/time_map_1.pdf')
    psToPDF('tmp/time_map_2.ps', 'tmp/time_map_2.pdf')

    mergePDFs(`${OUTPUT}/time_map_results_${safeDateString}.pdf`, 'tmp/time_map_info_text.pdf', 'tmp/time_map_1.pdf', 'tmp/time_map_2.pdf')

    fs.rmdirSync('tmp', { recursive: true })
  }
}

module.exports = ModuleOne
