const fs = require('fs')
const { addOsm, getCoordinates, gpkgOut, grass, mapsetExists } = require('../grass')
const { checkWritableDir } = require('../helpers')
const { add_location: messages } = require('../messages.json')

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GRASS = process.env.GRASS_DIR

module.exports = class {
  constructor() { }

  launch() {
    checkWritableDir(GEOSERVER)

    if (mapsetExists('PERMANENT')) {
      return messages["1"]
    }
    return messages["4"]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'add_location.1':
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
        // use buildings/municipality boundaries to set the location bbox
        grass('PERMANENT', `g.region vector=polygons_osm`)
        grass('PERMANENT', 'v.in.region output=location_bbox')
        gpkgOut('PERMANENT', 'location_bbox', 'location_bbox')

        let [east, north] = getCoordinates('PERMANENT')

        let msg = messages["5"]
        msg.message.lat = north
        msg.message.lon = east
        return msg
      }
    }
  }
}
