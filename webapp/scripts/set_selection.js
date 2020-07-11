const { addVector, clip, getCoordinates, gpkgOut, mapsetExists, remove } = require('./functions')

const BROWSER = process.env.DATA_FROM_BROWSER_DIR

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

  processFile(filename, replyTo) {
    if (replyTo == 'set_selection.2') {
      if (!filename.match(/\.geojson$/i)) {
        throw new Error("Wrong file format - must be 'geojson'")
      }

      remove('PERMANENT', 'selection')
      addVector('PERMANENT', `${BROWSER}/${filename}`, 'selection')

      gpkgOut('PERMANENT', 'selection', 'selection')

      // Clip the basemaps by the selection map. Results will be used in the calculations and analyses
      clip('PERMANENT', 'polygons_osm', 'selection', 'polygons')
      clip('PERMANENT', 'lines_osm', 'selection', 'lines')
      clip('PERMANENT', 'relations_osm', 'selection', 'relations')

      let [east, north] = getCoordinates('PERMANENT')

      let msg = this.messages[3]
      msg.message.lat = north
      msg.message.lon = east
      return msg
    }
  }
}

module.exports = SetSelectionModule
