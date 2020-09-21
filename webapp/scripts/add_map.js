const { addRaster, addVector, checkWritableDir, mapsetExists, gpkgOut } = require('./functions.js')
const { addDatastore, addFeatureType } = require('./geoserver.js')
const { add_map: messages } = require('./messages.json')

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`

class AddMapModule {
  constructor() {
    this.mapType = '' // 'vector' or 'raster'
    this.mapFile = '' // filename of uploaded file
  }

  launch() {
    checkWritableDir(GEOSERVER)

    if (mapsetExists('PERMANENT')) {
      return messages["2"]
    }
    return messages["1"]
  }

  async process(message, replyTo) {
    switch (replyTo) {
      case 'add_map.2':
        // uploaded file
        if (message.match(/\.geojson$|\.gpkg$|\.osm$/i)) {
          this.mapType = 'vector'
        } else if (message.match(/\.tiff?$|\.gtif$/i)) {
          this.mapType = 'raster'
        } else {
          throw new Error("Wrong file format - must be one of 'geojson', 'gpkg', 'osm', 'tif', 'tiff', 'gtif'")
        }

        this.mapFile = message
        return messages["3"]

      case 'add_map.3': {
        const mapName = message
        if (!mapName.match(/^[a-zA-Z]\w*$/)) {
          throw new Error("Invalid map name. Use alphanumeric characters only")
        }

        if (!this.mapFile) {
          throw new Error("File not found")
        }

        if (this.mapType === 'vector') {
          addVector('PERMANENT', this.mapFile, mapName)
          gpkgOut('PERMANENT', mapName, mapName)

          if (this.mapFile.match(/.*.gpkg/i)) {
            await addDatastore('vector', {
              dataStore: {
                name: mapName,
                connectionParameters: {
                  entry: [
                    { "@key": "database", "$": `file://${GEOSERVER}/${this.mapFile}` },
                    { "@key": "dbtype", "$": "geopkg" }
                  ]
                }
              }
            })
            await addFeatureType('vector', mapName, {
              featureType: {
                "name": mapName,
                "namespace": {
                  "name": 'vector',
                  "href": "http://localhost:8080/geoserver/rest/namespaces/vector.json"
                },
                "title": mapName,
                "keywords": {
                  "string": [
                    "features",
                    mapName
                  ]
                },
                "nativeCRS": "GEOGCS[\"WGS 84\", \n  DATUM[\"World Geodetic System 1984\", \n    SPHEROID[\"WGS 84\", 6378137.0, 298.257223563, AUTHORITY[\"EPSG\",\"7030\"]], \n    AUTHORITY[\"EPSG\",\"6326\"]], \n  PRIMEM[\"Greenwich\", 0.0, AUTHORITY[\"EPSG\",\"8901\"]], \n  UNIT[\"degree\", 0.017453292519943295], \n  AXIS[\"Geodetic longitude\", EAST], \n  AXIS[\"Geodetic latitude\", NORTH], \n  AUTHORITY[\"EPSG\",\"4326\"]]",
                "srs": "EPSG:4326",
                "nativeBoundingBox": {
                  "minx": -180,
                  "maxx": 180,
                  "miny": -90,
                  "maxy": 90,
                  "crs": "EPSG:4326"
                },
                "latLonBoundingBox": {
                  "minx": -180,
                  "maxx": 180,
                  "miny": -90,
                  "maxy": 90,
                  "crs": "EPSG:4326"
                },
                "projectionPolicy": "FORCE_DECLARED",
                "enabled": true,
                "metadata": {
                  "entry": {
                    "@key": "cachingEnabled",
                    "$": "false"
                  }
                },
                "store": {
                  "@class": "dataStore",
                  "name":  `vector:${mapName}`,
                  "href": `http://localhost:8080/geoserver/rest/workspaces/vector/datastores/${mapName}.json`
                },
                "serviceConfiguration": false,
                "maxFeatures": 0,
                "numDecimals": 0,
                "padWithZeros": false,
                "forcedDecimal": false,
                "overridingServiceSRS": false,
                "skipNumberMatched": false,
                "circularArcPresent": false,
                "attributes": {
                  "attribute": [
                    {
                      "name": "geom",
                      "minOccurs": 0,
                      "maxOccurs": 1,
                      "nillable": true,
                      "binding": "org.locationtech.jts.geom.Polygon"
                    },
                    {
                      "name": "cat",
                      "minOccurs": 0,
                      "maxOccurs": 1,
                      "nillable": true,
                      "binding": "java.lang.Integer"
                    }
                  ]
                }
              }
            })
          }
        } else if (this.mapType === 'raster') {
          addRaster('PERMANENT', this.mapFile, message)
        }
        return messages["4"]
      }
    }
  }
}

module.exports = AddMapModule
