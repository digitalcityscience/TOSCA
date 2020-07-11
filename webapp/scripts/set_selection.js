const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html

const { addVector, getCoordinates, gpkgOut, mapsetExists } = require('./functions')

const BROWSER = process.env.DATA_FROM_BROWSER_DIR
const GRASS = process.env.GRASS_DIR

class SetSelectionModule {
  constructor() {
    this.messages = {
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
        message: { "text": "Process finished, selection is saved." }
      }
    }
  }

  launch() {
    if (mapsetExists('PERMANENT')) {
      return this.messages[2]
    }
    return this.messages[1]
  }

  processFile(filename) {
    if (!filename.match(/\.geojson$/i)) {
      throw new Error("Wrong file format - must be GeoJSON")
    }

    const geojsonFile = `${BROWSER}/${filename}`;

    execSync(`grass "${GRASS}"/global/PERMANENT --exec g.remove -f type=vector name=selection`)

    addVector('PERMANENT', geojsonFile, 'selection')
    gpkgOut('PERMANENT', 'selection', 'selection')

    // Running Set resolution module
    // TODO

    // Clipping the basemaps by the selection map. Results will be used in the calculations and analysis
    execSync(`grass "${GRASS}"/global/PERMANENT --exec v.clip input=polygons_osm clip=selection output=polygons --overwrite`)
    execSync(`grass "${GRASS}"/global/PERMANENT --exec v.clip input=lines_osm clip=selection output=lines --overwrite`)
    execSync(`grass "${GRASS}"/global/PERMANENT --exec v.clip input=relations_osm clip=selection output=relations --overwrite`)

    // Finally, have to set Geoserver to display raster outputs (such as time_map) properly.
    // For this end, first have to prepare a "fake time_map". This is a simple geotiff, a raster version of "selection" vector map.
    // This will be exported to geoserver data dir as "time_map.tif".
    // Now the Geoserver have to be restarted manually and from that point, rastermaps of this locations will accepted automatically.
    // This process only have to repeated, when new location is created.
    // First check if a new location was created, or only a refining of the current selection:
    // TODO

    let [east, north] = getCoordinates('PERMANENT')

    let msg = this.messages[3]
    msg.message.lat = north
    msg.message.lon = east
    return msg
  }
}

module.exports = SetSelectionModule
