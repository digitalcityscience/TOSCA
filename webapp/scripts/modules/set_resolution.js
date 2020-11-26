const fs = require('fs')
const { grass, mapsetExists } = require('../grass')
const { checkWritableDir } = require('../helpers')
const translations = require(`../../i18n/messages.${process.env.USE_LANG || 'en'}.json`)

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GRASS = process.env.GRASS_DIR

module.exports = class {
  constructor() { }

  launch() {
    checkWritableDir(GEOSERVER)

    if (!mapsetExists('PERMANENT')) {
      return { id: 'set_resolution.7', message: translations['set_resolution.message.7'] }
    }

    return { id: 'set_resolution.1', message: translations['set_resolution.message.1'] }
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'set_resolution.1':
      case 'set_resolution.2': {
        const resolution = parseInt(message)

        if (resolution <= 0) {
          return { id: 'set_resolution.2', message: translations['set_resolution.message.2'] }
        } else {
          // [0] resolution in meters as given by the user
          // [1] resolution in decimal degrees, derived from resolution in meters
          const resolutionDeg = resolution / 111322
          const data = [resolution, resolutionDeg]
          fs.writeFileSync(`${GRASS}/variables/resolution`, data.join('\n'))

          // Finally, have to set Geoserver to display raster outputs (such as time_map) properly.
          // For this end, first have to prepare a "fake time_map". This is a simple geotiff, a raster version of "selection" vector map.
          // This will be exported to geoserver data dir as "time_map.tif".
          grass('PERMANENT', `g.region vector=selection res=${resolutionDeg}`)
          grass('PERMANENT', `v.to.rast input=selection output=m1_time_map use=val value=1 --overwrite`)
          grass('PERMANENT', `r.out.gdal input=m1_time_map output="${GEOSERVER}/m1_time_map.tif" format=GTiff type=Float64 --overwrite`)

          return { id: 'set_resolution.3', message: translations['set_resolution.message.3'] }
        }
      }
    }
  }
}
