const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html

const { Add_Vector, Get_Coordinates, Gpkg_Out } = require('./functions.js')

const BROWSER = process.env.DATA_FROM_BROWSER_DIR
const GRASS = process.env.GRASS_DIR
const MAPSET = `${GRASS}/global/PERMANENT`
const VARIABLES = `./variables`

const messages = {
  1: {
    message_id: 'set_selection.1',
    message: { "text": "No valid location found. First have to add a location to the dataset. Without such location, CityApp will not work. To add a location, use Add Location menu. Now click OK to exit." }
  },
  2: {
    message_id: 'set_selection.2',
    message: { "text": "Now zoom to area of your interest, then use drawing tool to define your location. Next, save your selection." }
  },
  3: {
    message_id: 'set_selection.3',
    message: { "text": "Process finished, selection is saved. To process exit, click OK." }
  }
}

class SetSelectionModule {
  launch() {
    // Check if a PERMANENT mapset exists
    let location = true
    try {
      execSync(`grass "${MAPSET}" --exec g.list type=vector`)
    } catch (err) {
      location = false
    }

    if (!location) {
      return messages[1]
    }
    return messages[2]
  }

  process(message, replyTo) {
  }

  processFile(filename) {
    if (!filename.match(/\.geojson$/i)) {
      throw new Error("Wrong file format - must be GeoJSON")
    }

    const GEOJSON_FILE = `${BROWSER}/${filename}`;

    execSync(`grass "${MAPSET}" --exec g.remove -f type=vector name=selection`)

    Add_Vector(MAPSET, GEOJSON_FILE, 'selection')
    Gpkg_Out(MAPSET, 'selection', 'selection')

    // Running Set resolution module
    // TODO

    // Refine or redefine the area selection
    execSync(`rm -f "${VARIABLES}"/location_new`)
    execSync(`touch "${VARIABLES}"/location_mod`)

    // Clipping the basemaps by the selection map. Results will be used in the calculations and analysis
    execSync(`grass "${MAPSET}" --exec v.clip input=polygons_osm clip=selection output=polygons --overwrite`)
    execSync(`grass "${MAPSET}" --exec v.clip input=lines_osm clip=selection output=lines --overwrite`)
    execSync(`grass "${MAPSET}" --exec v.clip input=relations_osm clip=selection output=relations --overwrite`)

    // Finally, have to set Geoserver to display raster outputs (such as time_map) properly.
    // For this end, first have to prepare a "fake time_map". This is a simple geotiff, a raster version of "selection" vector map.
    // This will be exported to geoserver data dir as "time_map.tif".
    // Now the Geoserver have to be restarted manually and from that point, rastermaps of this locations will accepted automatically.
    // This process only have to repeated, when new location is created.
    // First check if a new location was created, or only a refining of the current selection:
    // TODO

    let [EAST, NORTH] = Get_Coordinates(MAPSET)

    let msg = messages[3]
    msg.message.lat = NORTH
    msg.message.lon = EAST
    return msg
  }
}

module.exports = SetSelectionModule
