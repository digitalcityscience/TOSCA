const fs = require('fs')
const { addVector, checkWritableDir, gpkgOut, initMapset, listVector, mapsetExists, grass, mergePDFs, psToPDF, textToPS } = require('./functions')
const { module_1a: messages } = require('./messages.json')

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GRASS = process.env.GRASS_DIR
const OUTPUT = process.env.OUTPUT_DIR

const AVERAGE_SPEED = 40
const ROAD_POINTS = 0.003
const CONNECT_DISTANCE = 0.003
const CONVERSION_RESOLUTION = 0.0001
const METER_TO_PROJ = 111320 // length of a degree of latitude, or of a degree of longitude at the equator, in meters

class ModuleOneA {
  constructor() { }

  launch() {
    checkWritableDir(GEOSERVER)
    checkWritableDir(OUTPUT)

    if (!mapsetExists('PERMANENT')) {
      return messages["7"]
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
    grass('module_1', `v.edit map=m1_stricken_area_line tool=create --overwrite`)

    return messages["1"]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'module_1a.1':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_1', message, 'm1_from_points')
          gpkgOut('module_1', 'm1_from_points', `${GEOSERVER}/m1_from_points.gpkg`)
          this.fromPoints = 'm1_from_points'
          return messages["2"]
        }
        return messages["5"]

      case 'module_1a.2':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_1', message, 'm1_via_points')
          gpkgOut('module_1', 'm1_via_points', `${GEOSERVER}/m1_via_points.gpkg`)
          this.viaPoints = 'm1_via_points'
          return messages["3"]
        } else {
          this.viaPoints = null
        }
        return messages["3"]

      case 'module_1a.3':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_1', message, 'm1_stricken_area')
          gpkgOut('module_1', 'm1_stricken_area', `${GEOSERVER}/m1_stricken_area.gpkg`)
          this.strickenArea = 'm1_stricken_area'
          return messages["4"]
        }
        return messages["8"]

      case 'module_1a.4':
        this.reductionRatio = parseFloat(message) / 100
        return messages["8"]

      case 'module_1a.8':
        if (message.toLowerCase() == 'yes') {
          return messages["9"]
        }
        this.average_speed = AVERAGE_SPEED
        this.calculate()
        return messages["6"]

      case 'module_1a.9':
        this.average_speed = message
        this.calculate()
        return messages["6"]

    }
  }

  calculate() {
    console.log("Calculating time map …")

    // Setting region to fit the "selection" map (taken by location_selector) and resolution
    grass('module_1', `g.region vector=selection@PERMANENT res=${this.resolution} --overwrite`)

    // "TO" points has a default value, the points of the road network will used for. But, because these points are on the road by its origin, therefore no further connecting is requested.
    grass('module_1', `v.to.points input=highways@PERMANENT output=m1a_highway_points dmax=${ROAD_POINTS} --overwrite`)
    this.toPoints = 'm1a_highway_points'

    // threshold to connect is ~ 330 m
    grass('module_1', `v.net input=highways points=${this.fromPoints} output=m1a_highways_from_points operation=connect threshold=${CONNECT_DISTANCE} --overwrite`)

    // connecting from/via/to points to the clipped network, if neccessary. Via points are optional, first have to check if user previously has selected those or not.
    if (this.viaPoints) {
      grass('module_1', `v.net input=highways points=${this.viaPoints} output=m1a_highways_via_points operation=connect threshold=${CONNECT_DISTANCE} --overwrite`)
      grass('module_1', `v.patch -e input=m1a_highways_via_points,m1a_highways_from_points output=m1a_highways_points_connected --overwrite`)
    } else {
      grass('module_1', `g.rename vector=m1a_highways_from_points,m1a_highways_points_connected`)
    }

    // Add "spd_average" attribute column (integer type) to the road network map (if not yet exist -- if exist GRASS will skip this process)
    grass('module_1', `v.db.addcolumn map=m1a_highways_points_connected columns='avg_speed INT'`)

    // Now updating the datatable of highways_points_connected map, using "roads_speed" file to get speed data and conditions.
    for (const [where, value] of this.roadSpeedValues) {
      grass('module_1', `v.db.update map=m1a_highways_points_connected layer=1 column=avg_speed value=${value} where="${where.replace(/"/g, '\\"')}"`)
    }

    // Converting clipped and connected road network map into raster format and float number
    grass('module_1', `v.extract -r input=m1a_highways_points_connected@module_1 where="avg_speed>0" output=m1a_temp_connections --overwrite`)
    grass('module_1', `v.to.rast input=m1a_temp_connections output=m1a_temp_connections use=val value=${this.average_speed} --overwrite`)
    grass('module_1', `v.to.rast input=m1a_highways_points_connected output=m1a_highways_points_connected_1 use=attr attribute_column=avg_speed --overwrite`)
    grass('module_1', `r.patch input=m1a_temp_connections,m1a_highways_points_connected_1 output=m1a_highways_points_connected --overwrite`)
    grass('module_1', `r.mapcalc expression="m1a_highways_points_connected=float(m1a_highways_points_connected)" --overwrite`)

    // Now vector zones are created around from and via points (its radius is equal to the current resolution),
    // converted into raster format, and patched to raster map 'temp' (just created in the previous step)
    if (this.viaPoints) {
      grass('module_1', `v.patch -e input=${this.fromPoints},${this.viaPoints} output=m1a_from_via_points --overwrite`)
      grass('module_1', `v.buffer input=m1a_from_via_points output=m1a_from_via_zones distance=${this.resolution} --overwrite`)
    } else {
      grass('module_1', `v.buffer input=${this.fromPoints} output=m1a_from_via_zones distance=${this.resolution} --overwrite`)
    }
    grass('module_1', `v.to.rast input=m1a_from_via_zones output=m1a_from_via_zones use=val val=${this.average_speed} --overwrite`)
    grass('module_1', `r.patch input=m1a_highways_points_connected,m1a_from_via_zones output=m1a_highways_points_connected_zones --overwrite`)

    // Now the Supplementary lines (formerly CAT_SUPP_LINES) raster map have to be added to map highways_from_points. First I convert highways_points_connected into raster setting value to 0(zero). Resultant map: temp. After I patch temp and highways_points_connected, result is:highways_points_connected_temp. Now have to reclass highways_points_connected_temp, setting 0 values to the speed value of residentals
    grass('module_1', `v.to.rast input=m1a_highways_points_connected output=m1a_temp use=val val=${this.average_speed} --overwrite`)
    grass('module_1', `r.patch input=m1a_highways_points_connected_zones,m1a_temp output=m1a_highways_points_connected_temp --overwrite`)

    if (this.strickenArea) {
      grass('module_1', `v.to.rast input=${this.strickenArea} output=${this.strickenArea} use=val value=${this.reductionRatio} --overwrite`)
      grass('module_1', `r.null map=${this.strickenArea} null=1 --overwrite`)
      grass('module_1', `r.mapcalc expression="m1a_highways_points_connected_area_temp=(m1a_highways_points_connected_temp*${this.strickenArea})" --overwrite`)
    } else {
      grass('module_1', `g.rename raster=m1a_highways_points_connected_temp,m1a_highways_points_connected_area_temp --overwrite`)
    }
    grass('module_1', `r.mapcalc expression="m1a_highways_points_connected_area=(m1a_highways_points_connected_area_temp*1)" --overwrite`)

    // specific_time here is the time requested to cross a cell, where the resolution is as defined in resolution file
    grass('module_1', `r.mapcalc expression="m1a_specific_time=${this.resolution}/(m1a_highways_points_connected_area*0.27777)" --overwrite`)

    // Calculating 'from--via' time map, 'via--to' time map and it sum. There is a NULL value replacenet too. It is neccessary, because otherwise, if one of the maps containes NULL value, NULL value cells will not considering while summarizing the maps. Therefore, before mapcalc operation, NULL has to be replaced by 0.
    // FIXME: when this.viaPoints == true, PDF results has a green background, probably due to null raster cells
    if (this.viaPoints) {
      grass('module_1', `r.cost -n input=m1a_specific_time output=m1a_from_to_cost start_points=${this.fromPoints} stop_points=${this.viaPoints} null_cost=0 --overwrite`)
      const VIA_VALUE = grass('module_1', `r.what map=m1a_from_to_cost points=${this.viaPoints}`).split('|')[3]
      grass('module_1', `r.cost -n input=m1a_specific_time output=m1a_via_to_cost start_points=${this.viaPoints} stop_points=${this.toPoints} null_cost=0 --overwrite`)
      grass('module_1', `r.mapcalc expression="m1a_time_map_temp=m1a_via_to_cost+${VIA_VALUE}" --overwrite`)
      grass('module_1', `r.mapcalc expression="m1a_time_map=m1a_time_map_temp*${METER_TO_PROJ}" --overwrite`)
    } else {
      grass('module_1', `r.cost input=m1a_specific_time output=m1a_from_to_cost start_points=${this.fromPoints} stop_points=${this.toPoints} --overwrite`)
      grass('module_1', `r.mapcalc expression="m1a_time_map_temp=m1a_from_to_cost*${METER_TO_PROJ}/60" --overwrite`)
      grass('module_1', `g.rename raster=m1a_time_map_temp,m1a_time_map --overwrite`)
    }

    // export raster map
    grass('module_1', `r.out.gdal input=m1a_time_map output="${GEOSERVER}/m1_time_map.tif" format=GTiff --overwrite`)

    if (this.strickenArea) {
      grass('module_1', `v.type input=m1_stricken_area output=m1_stricken_area_lines from_type=boundary to_type=line --overwrite`)
    }

    // Converting the result into vector point format
    grass('module_1', `g.region res=${CONVERSION_RESOLUTION}`)
    grass('module_1', `r.to.vect input=m1a_time_map output=m1_time_map type=point column=data --overwrite`)
    grass('module_1', `v.out.ogr -s input=m1_time_map@module_1 type=point output="${GEOSERVER}/m1_time_map.gpkg" --overwrite`)

    // Generating pdf output

    let psParams = fs.readFileSync(`${GRASS}/variables/defaults/module_1a.ps_param`).toString()

    if (this.viaPoints) {
      psParams += `
vpoints m1_via_points
color black
fcolor #ff77ff
symbol basic/cross3
size 10
end
`
    }

    if (this.strickenArea) {
      psParams += `
vlines m1_stricken_area_lines
color #000000
width 0.4
masked n
end
`
    }

    fs.writeFileSync(`${GRASS}/variables/module_1a.ps_param`, psParams)

    // set color for maps:
    grass('module_1', `g.region res=${this.resolution}`)
    grass('module_1', `r.colors -e map=m1a_time_map color=gyr`)

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
Stricken area: black line

Considered speed on roads:
${this.roadsSpeed.join('\n')}

Speed reduction coefficient for stricken area: ${this.reductionRatio}`)

    textToPS('tmp/time_map_info_text', 'tmp/time_map_info_text.ps')
    psToPDF('tmp/time_map_info_text.ps', 'tmp/time_map_info_text.pdf')

    grass('module_1', `ps.map input="${GRASS}/variables/module_1a.ps_param" output=tmp/time_map_1.ps --overwrite`)
    psToPDF('tmp/time_map_1.ps', 'tmp/time_map_1.pdf')

    mergePDFs(`${OUTPUT}/time_map_results_${safeDateString}.pdf`, 'tmp/time_map_1.pdf', 'tmp/time_map_info_text.pdf')

    grass('module_1', `g.remove -f type=vector pattern=temp_*`)
    grass('module_1', `g.remove -f type=vector pattern=m1a_*`)

    fs.rmdirSync('tmp', { recursive: true })
  }
}

module.exports = ModuleOneA
