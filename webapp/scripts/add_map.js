const { addRaster, addVector, mapsetExists } = require('./functions.js')

const BROWSER = process.env.DATA_FROM_BROWSER_DIR

class AddMapModule {
  constructor() {
    this.messages = {
      1: {
        message_id: 'add_map.1',
        message: { "text": "Selection map not found. Before adding a new layer, first you have to define a location and a selection. For this end please, use Location Selector tool of CityApp." }
      },
      2: {
        message_id: 'add_map.2',
        message: { "text": "Select a map to add CityApp. Only gpkg (geopackage), geojson and openstreetmap vector files and geotiff (gtif or tif) raster files are accepted. Adding a map may take a long time." }
      },
      3: {
        message_id: 'add_map.3',
        message: { "text": "Please, define an output map name. Name can contain only english characters, numbers, or underline character. Space and other specific characters are not allowed. For first character a letter only accepted." }
      },
      4: {
        message_id: 'add_map.4',
        message: { "text": "Selected map is now succesfully added to your mapset." }
      }
    }
    this.mapType = '' // 'vector' or 'raster'
    this.mapFile = '' // filename of uploaded file
  }

  launch() {
    if (mapsetExists('PERMANENT')) {
      return this.messages[2]
    }
    return this.messages[1]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'add_map.3':
        if (!message.match(/^[a-zA-Z]\w*$/)) {
          throw new Error("Invalid map name. Use alphanumeric characters only")
        }

        if (!this.mapFile) {
          throw new Error("File not found")
        }

        if (this.mapType === 'vector') {
          addVector('PERMANENT', this.mapFile, message)
        } else if (this.mapType === 'raster') {
          addRaster('PERMANENT', this.mapFile, message)
        }

        return this.messages[4]
    }
  }

  processFile(filename) {
    if (filename.match(/\.geojson$|\.gpkg$|\.osm$/i)) {
      this.mapType = 'vector'
    } else if (filename.match(/\.tiff?$|\.gtif$/i)) {
      this.mapType = 'raster'
    } else {
      throw new Error("Wrong file format - must be one of 'geojson', 'gpkg', 'osm', 'tif', 'tiff', 'gtif'")
    }

    this.mapFile = `${BROWSER}/${filename}`

    return this.messages[3]
  }
}

module.exports = AddMapModule
