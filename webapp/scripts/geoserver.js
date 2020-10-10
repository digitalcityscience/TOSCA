const axios = require('axios')
const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GEOSERVER_URL = process.env.GEOSERVER_URL

const geoServer = axios.create({
  baseURL: GEOSERVER_URL,
  auth: {
    username: process.env.GEOSERVER_USERNAME,
    password: process.env.GEOSERVER_PASSWORD
  }
})

module.exports = {
  /**
   * add a datastore (a map data source) through Geoserver REST API
   * @param {String} datastoreName 
   * @param {String} workspaceName 
   * @param {String} databaseFile 
   */
  async addDatastore(datastoreName, workspaceName , databaseFile) {
    const body = dataStore(datastoreName, `file://${GEOSERVER}/${databaseFile}`)
    const res = await geoServer.post(`/rest/workspaces/${workspaceName}/datastores`, body)
    return res.data
  },
  /**
   * add and publish a featureType (map layer) through Geoserver REST API
   * @param {String} featuretypeName 
   * @param {String} datastoreName 
   * @param {String} workspaceName 
   */
  async addFeatureType(featuretypeName, datastoreName, workspaceName) {
    const body = featureType(featuretypeName, datastoreName)
    const res = await geoServer.post(`/rest/workspaces/${workspaceName}/datastores/${datastoreName}/featuretypes/`, body)
    return res.data
  },
}

function dataStore(datastoreName, databaseFile) {
  return {
    dataStore: {
      name: datastoreName,
      connectionParameters: {
        entry: [
          { "@key": "database", "$": databaseFile },
          { "@key": "dbtype", "$": "geopkg" }
        ]
      }
    }
  }
}

function featureType(featuretypeName, datastoreName) {
  return {
    featureType: {
      "name": featuretypeName,
      "namespace": {
        "name": 'vector',
        "href": `${GEOSERVER_URL}/rest/namespaces/vector.json`
      },
      "title": featuretypeName,
      "keywords": {
        "string": [
          "features",
          featuretypeName
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
        "name": `vector:${datastoreName}`,
        "href": `${GEOSERVER_URL}/rest/workspaces/vector/datastores/${datastoreName}.json`
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
  }
}