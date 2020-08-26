const fs = require('fs')
const { addOsm, getCoordinates, gpkgOut, mapsetExists } = require('./functions')
const { add_location: messages } = require('./messages.json')

const GRASS = process.env.GRASS_DIR

class AddLocationModule {
  constructor() { }

  launch() {
    if (mapsetExists('PERMANENT')) {
      return messages["1"]
    }
    return messages["2"]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'add_location.1':
      case 'add_location.2':
        if (message.toLowerCase() == 'yes') {
          return messages["4"]
        }
        return messages["3"]

      case 'add_location.4': {
        // uploaded file
        if (!message.match(/\.osm$/i)) {
          throw new Error("Wrong file format - must be 'osm'")
        }

        // Clear previous mapset
        fs.rmdirSync(`${GRASS}/global/PERMANENT`, { recursive: true })
        fs.mkdirSync(`${GRASS}/global/PERMANENT`)
        for (const file of fs.readdirSync(`${GRASS}/skel_permanent`)) {
          fs.copyFileSync(`${GRASS}/skel_permanent/${file}`, `${GRASS}/global/PERMANENT/${file}`)
        }

        // Import new map data
        addOsm('PERMANENT', message, 'points', 'points_osm')
        addOsm('PERMANENT', message, 'lines', 'lines_osm')
        addOsm('PERMANENT', message, 'multipolygons', 'polygons_osm')
        addOsm('PERMANENT', message, 'other_relations', 'relations_osm')

        gpkgOut('PERMANENT', 'points_osm', 'points')
        gpkgOut('PERMANENT', 'lines_osm', 'lines')
        gpkgOut('PERMANENT', 'polygons_osm', 'polygons')

        let [east, north] = getCoordinates('PERMANENT')

        let msg = messages["5"]
        msg.message.lat = north
        msg.message.lon = east
        return msg
      }
    }
  }
}

module.exports = AddLocationModule
