const { addVector, checkWritableDir, clip, getCoordinates, gpkgOut, mapsetExists, remove, grass } = require('./functions')
const translations = require(`../i18n/messages.${process.env.USE_LANG || 'en'}.json`)

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`

class SetSelectionModule {
  constructor() { }

  launch() {
    checkWritableDir(GEOSERVER)

    if (mapsetExists('PERMANENT')) {
      return { id: 'set_selection.2', message: translations['set_selection.message.2'] }
    }
    return { id: 'set_selection.1', message: translations['set_selection.message.1'] }
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'set_selection.2': {
        // uploaded file
        if (!message.match(/\.geojson$/i)) {
          throw new Error(translations['set_selection.errors.1'])
        }

        remove('PERMANENT', 'selection')
        addVector('PERMANENT', message, 'selection')

        gpkgOut('PERMANENT', 'selection', 'selection')

        // Clip the basemaps by the selection map. Results will be used in the calculations and analyses
        clip('PERMANENT', 'polygons_osm', 'selection', 'polygons')
        clip('PERMANENT', 'lines_osm', 'selection', 'lines')
        clip('PERMANENT', 'relations_osm', 'selection', 'relations')

        // highways is not a basemap, but it is faster to create it once now, that many times later in module_1
        grass('PERMANENT', `v.extract input=lines type=line where="highway>0" output=highways --overwrite`)

        let [east, north] = getCoordinates('PERMANENT')

        return {
          id: 'set_selection.3',
          message: translations['set_selection.message.3'],
          lat: north,
          lon: east
        }
      }
    }
  }
}

module.exports = SetSelectionModule
