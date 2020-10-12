const { addVector, checkWritableDir, clip, getCoordinates, gpkgOut, mapsetExists, remove, grass } = require('./functions')
const { set_selection: messages } = require('./messages.json')

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`

class SetSelectionModule {
  constructor() { }

  launch() {
    checkWritableDir(GEOSERVER)

    if (mapsetExists('PERMANENT')) {
      return messages["2"]
    }
    return messages["1"]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'set_selection.2': {
        // uploaded file
        if (!message.match(/\.geojson$/i)) {
          throw new Error("Wrong file format - must be 'geojson'")
        }

        remove('PERMANENT', 'selection')
        addVector('PERMANENT', message, 'selection')

        gpkgOut('PERMANENT', 'selection', `${GEOSERVER}/selection.gpkg`)

        // Clip the basemaps by the selection map. Results will be used in the calculations and analyses
        clip('PERMANENT', 'polygons_osm', 'selection', 'polygons')
        clip('PERMANENT', 'lines_osm', 'selection', 'lines')
        clip('PERMANENT', 'relations_osm', 'selection', 'relations')

        // highways is not a basemap, but it is faster to create it once now, that many times later in module_1
        grass('PERMANENT', `v.extract input=lines type=line where="highway>0" output=highways --overwrite`)

        let [east, north] = getCoordinates('PERMANENT')

        let msg = messages["3"]
        msg.message.lat = north
        msg.message.lon = east
        return msg
      }
    }
  }
}

module.exports = SetSelectionModule
