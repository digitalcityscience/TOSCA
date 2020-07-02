const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html

const { addOsm, getCoordinates, gpkgOut, mapsetExists } = require('./functions')

const BROWSER = process.env.DATA_FROM_BROWSER_DIR
const GRASS = process.env.GRASS_DIR
const VARIABLES = `./variables`

class AddLocationModule {
  constructor() {
    this.messages = {
      1: {
        message_id: 'add_location.1',
        message: { "text": "There is an already added location, and it is not allowed to add further locations. If you want to add a new location, the already existing location will automatically removed. If you want to store the already existing location, save manually (refer to the manual, please). Do you want to add a new location? If yes, click Yes." }
      },
      2: {
        message_id: 'add_location.2',
        message: { "text": "No valid location found. First have to add a location to the dataset. Without such location, CityApp will not work. Adding a new location may take a long time, depending on the file size. If you want to continue, click Yes." }
      },
      3: {
        message_id: 'add_location.3',
        message: { "text": "Process cancelled." }
      },
      4: {
        message_id: 'add_location.4',
        message: { "text": "Select a map to add to CityApp. Map has to be in Open Street Map format -- osm is the only accepted format." }
      },
      5: {
        message_id: 'add_location.5',
        message: { "text": "New location is set." }
      }
    }
  }

  launch() {
    if (mapsetExists('PERMANENT')) {
      return this.messages[1]
    }
    return this.messages[2]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'add_location.1':
        if (message.toLowerCase() == 'yes') {
          return this.messages[4]
        }
        return this.messages[3]
      case 'add_location.2':
        if (message.toLowerCase() == 'yes') {
          return this.messages[4]
        }
        return this.messages[3]
    }
  }

  processFile(filename) {
    if (!filename.match(/\.osm$/i)) {
      throw new Error("Wrong file format - must be OSM")
    }

    const osmFile = `${BROWSER}/${filename}`

    execSync(`rm -fr "${GRASS}"/global/PERMANENT`)
    execSync(`mkdir "${GRASS}"/global/PERMANENT`)
    execSync(`cp -r "${GRASS}"/skel_permanent/* "${GRASS}"/global/PERMANENT`)

    addOsm('PERMANENT', osmFile, 'points', 'points_osm')
    addOsm('PERMANENT', osmFile, 'lines', 'lines_osm')
    addOsm('PERMANENT', osmFile, 'multipolygons', 'polygons_osm')
    addOsm('PERMANENT', osmFile, 'other_relations', 'relations_osm')
    gpkgOut('PERMANENT', 'points_osm', 'points')
    gpkgOut('PERMANENT', 'lines_osm', 'lines')
    gpkgOut('PERMANENT', 'polygons_osm', 'polygons')

    execSync(`rm -f "${VARIABLES}"/location_mod`)
    execSync(`touch "${VARIABLES}"/location_new`)

    let [east, north] = getCoordinates('PERMANENT')

    let msg = this.messages[5]
    msg.message.lat = north
    msg.message.lon = east
    return msg
  }
}

module.exports = AddLocationModule
