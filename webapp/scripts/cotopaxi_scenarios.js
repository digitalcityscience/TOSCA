const { addVector, checkWritableDir, initMapset, mapsetExists, listVector, getColumns, getUnivar, grass, psToPDF } = require('./functions')

const GEOSERVER_DATA_DIR = process.env.GEOSERVER_DATA_DIR
const GRASS_DIR = process.env.GRASS_DIR
const OUTPUT_DIR = process.env.OUTPUT_DIR

const messages = {
  0: {
    "message_id": "cotopaxi_scenarios.0",
    "message": {
      "text": "Please choose a type of volcanic threat whose potential impact you want to analyze."
    }
  },
  1: {
    "message_id": "cotopaxi_scenarios.1",
    "message": {
      "text": "Before you can run the analysis, you need to add a dataset containing $1. Please select a file (.gpkg) to upload."
    }
  },
  2: {
    "message_id": "cotopaxi_scenarios.2",
    "message": {
      "text": "Select the affected area to consider for your analysis."
    }
  },
  3: {
    "message_id": "cotopaxi_scenarios.3",
    "message": {
      "text": "Now choose the map layer the effects on which you want to analyze."
    }
  },
  4: {
    "message_id": "cotopaxi_scenarios.4",
    "message": {
      "text": "Done."
    }
  },
  5: {
    "message_id": "cotopaxi_scenarios.5",
    "message": {
      "text": "There are no features overlapping with the risk area. No output has been produced."
    }
  },
}

// Map names (must not contain whitespace)
const queryZone = 'cotopaxi_scenarios_query_zone'
const queryResult = 'cotopaxi_scenarios_query_result'

module.exports = class {
  constructor() {
    this.mapset = 'cotopaxi_scenarios'
    this.datasets = []
  }

  launch() {
    checkWritableDir(`${GEOSERVER_DATA_DIR}/data`)

    if (!mapsetExists(this.mapset)) {
      initMapset(this.mapset)
    }

    return messages[0]
  }

  message2() {
    const columns = getColumns(this.mapset, this.zonesLayer)
    const list = columns.map(col => {
      col.rows = []
      // Extract a set of values appearing in the given dataset
      const set = new Set(grass(this.mapset, `db.select sql="SELECT ${col.name} FROM ${this.zonesLayer}"`).trim().split('\n').slice(1))
      for (const value of set.values()) {
        col.rows.push(value)
      }
      return col
    })
    const msg = messages[2]
    msg.message.list = list
    return msg
  }

  message3() {
    const msg = messages[3]
    msg.message.list = this.getQueryableDatasets()
    return msg
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'cotopaxi_scenarios.0': {
        // message should be one of ['ash_fall', 'lahar_flow', 'lava_flow']
        this.typeOfThreat = message
        this.zonesLayer = `${this.typeOfThreat}_zones`

        this.datasets = listVector(this.mapset)

        // If zones layer exists, jump to the next step …
        if (this.datasets.indexOf(this.zonesLayer) > -1) {
          return this.message2()
        }

        // … else request upload of dataset
        const msg = messages[1]
        msg.message.text = msg.message.text.replace(/\$1/, {
          "ash_fall": 'ash fall risk zones',
          "lahar_flow": 'lahar flow risk zones',
          "lava_flow": 'lava flow risk zones'
        }[this.typeOfThreat])
        return msg
      }

      case 'cotopaxi_scenarios.1': {
        // message is path of uploaded file
        if (!message.match(/\.gpkg$/i)) {
          throw new Error("Wrong file format - must be GeoPackage (.gpkg)")
        }

        addVector(this.mapset, message, `${this.typeOfThreat}_zones`)
        this.datasets = listVector(this.mapset)

        return this.message2()
      }

      case 'cotopaxi_scenarios.2': {
        // message is the "where" expression
        const [col, val] = message

        // Extract matching features and store them in queryZone
        grass(this.mapset, `v.extract input=${this.zonesLayer} where="${col} = ${val}" output=${queryZone} --overwrite`)

        return this.message3()
      }

      case 'cotopaxi_scenarios.3': {
        // message is a layer name
        this.selectLayer = message

        // Remove result layer from previous run if it exists
        grass(this.mapset, `g.remove -f type=vector name=${queryResult}`)

        // Select features from the layer using the query zone
        grass(this.mapset, `v.select ainput=${this.selectLayer} binput=${queryZone} output=${queryResult} operator=overlap --overwrite`)

        // Check if the query result is not empty
        try {
          getUnivar(this.mapset, queryResult, 'cat')
        } catch (err) {
          return messages[5]
        }

        // Set the region for the output map, using the bounds of queryResult
        grass(this.mapset, `g.region vector=${queryResult} --overwrite`)

        // Create PS output
        grass(this.mapset, `ps.map input="${GRASS_DIR}/variables/defaults/cotopaxi_scenarios.ps_param" output=cotopaxi_scenarios.ps --overwrite`)

        // Convert to PDF
        const dateString = new Date().toISOString().replace(/([\d-]*)T(\d\d):(\d\d):[\d.]*Z/g, '$1_$2$3')
        psToPDF('cotopaxi_scenarios.ps', `${OUTPUT_DIR}/cotopaxi_scenarios_${dateString}.pdf`)

        return messages[4]
      }
    }
  }

  getQueryableDatasets() {
    return this.datasets.filter(d => !d.match(/cotopaxi_scenarios.*|(ash_fall|lahar_flow|lava_flow)_zones|(lines|points|polygons|relations)(_osm)?|selection|location_bbox/))
  }
}
