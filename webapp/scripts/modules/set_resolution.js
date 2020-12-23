const fs = require('fs')
const { mapsetExists } = require('../grass')
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

          return { id: 'set_resolution.3', message: translations['set_resolution.message.3'] }
        }
      }
    }
  }
}
