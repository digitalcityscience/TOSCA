const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html

const { Add_Osm, Get_Coordinates, Gpkg_Out } = require('./functions.js')

const BROWSER = process.env.DATA_FROM_BROWSER_DIR
const GRASS = process.env.GRASS_DIR
const MAPSET = `${GRASS}/global/PERMANENT`
const VARIABLES = `./variables`

const messages = {
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
    message: { "text": "Exit process, click OK" }
  },
  4: {
    message_id: 'add_location.4',
    message: { "text": "Select a map to add to CityApp. Map has to be in Open Street Map format -- osm is the only accepted format." }
  },
  5: {
    message_id: 'add_location.5',
    message: { "text": "New location is set. To exit, click OK." }
  }
}

class AddLocationModule {
  launch() {
    // Check if a PERMANENT mapset exists
    let location = true
    try {
      execSync(`grass -f "${MAPSET}" --exec g.list type=vector`)
    } catch (err) {
      location = false
    }

    if (location) {
      return messages[1]
    }
    return messages[2]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'add_location.1':
        if (message.toLowerCase() == 'yes') {
          return messages[4]
        }
        return messages[3]
      case 'add_location.2':
        if (message.toLowerCase() == 'yes') {
          return messages[4]
        }
        return messages[3]
    }
  }

  processFile(filename) {
    if (!filename.match(/\.osm$/i)) {
      throw new Error("Wrong file format - must be OSM")
    }

    const NEW_AREA_FILE = `${BROWSER}/${filename}`;

    execSync(`rm -fr "${MAPSET}"`)
    execSync(`mkdir "${MAPSET}"`)
    execSync(`cp -r "${GRASS}"/skel_permanent/* "${MAPSET}"`)

    Add_Osm(MAPSET, NEW_AREA_FILE, 'points', 'points_osm')
    Add_Osm(MAPSET, NEW_AREA_FILE, 'lines', 'lines_osm')
    Add_Osm(MAPSET, NEW_AREA_FILE, 'multipolygons', 'polygons_osm')
    Add_Osm(MAPSET, NEW_AREA_FILE, 'other_relations', 'relations_osm')
    Gpkg_Out(MAPSET, 'points_osm', 'points')
    Gpkg_Out(MAPSET, 'lines_osm', 'lines')
    Gpkg_Out(MAPSET, 'polygons_osm', 'polygons')

    execSync(`rm -f "${VARIABLES}"/location_mod`)
    execSync(`touch "${VARIABLES}"/location_new`)

    let [EAST, NORTH] = Get_Coordinates(MAPSET)

    let msg = messages[5]
    msg.message.lat = NORTH
    msg.message.lon = EAST
    return msg
  }
}

module.exports = AddLocationModule
