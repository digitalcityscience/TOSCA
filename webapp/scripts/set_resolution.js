const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html
const fs = require('fs')

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GRASS = process.env.GRASS_DIR

class SetResolutionModule {
  constructor() {
    this.messages = {
      1: {
        message_id: 'set_resolution.1',
        message: { "text": "Type the resolution in meters, you want to use. For further details see manual." }
      },
      2: {
        message_id: 'set_resolution.2',
        message: { "text": "Resolution has to be an integer number, greater than 0. Please, define the resolution for calculations in meters." }
      },
      3: {
        message_id: 'set_resolution.3',
        message: { "text": "Resolution is now set." }
      }
    }
  }

  launch() {
    return this.messages[1]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'set_resolution.1':
      case 'set_resolution.2': {
        const resolution = parseInt(message)

        if (resolution <= 0) {
          return this.messages[2]
        } else {
          // [0] resolution in meters as given by the user
          // [1] resolution in decimal degrees, derived from resolution in meters
          const resolutionDeg = resolution/111322
          const data = [resolution, resolutionDeg]
          fs.writeFileSync(`${GRASS}/variables/resolution`, data.join("\n"))

          // Finally, have to set Geoserver to display raster outputs (such as time_map) properly.
          // For this end, first have to prepare a "fake time_map". This is a simple geotiff, a raster version of "selection" vector map.
          // This will be exported to geoserver data dir as "time_map.tif".
          execSync(`grass ${GRASS}/global/PERMANENT --exec g.region vector=selection res=${resolutionDeg}`)
          execSync(`grass ${GRASS}/global/PERMANENT --exec v.to.rast input=selection output=m1_time_map use=val value=1 --overwrite --quiet`)
          execSync(`grass ${GRASS}/global/PERMANENT --exec r.out.gdal input=m1_time_map output="${GEOSERVER}/m1_time_map.tif" format=GTiff type=Float64 --overwrite --quiet`)

          return this.messages[3]
        }
      }
    }
  }
}

module.exports = SetResolutionModule
