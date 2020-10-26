const { addVector, checkWritableDir, initMapset, mapsetExists, listVector, grass } = require('./functions')

const GEOSERVER_DATA_DIR = process.env.GEOSERVER_DATA_DIR

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
}

// Map names
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
    const columns = grass(this.mapset, `db.describe -c table=${this.zonesLayer}`).trim().split('\n')
    const zones = grass(this.mapset, `v.out.ascii input=${this.zonesLayer} columns="*"`).trim().split('\n')
    return {
      message_id: messages[2].message_id,
      message: {
        text: messages[2].message.text + '<br><br>' + columns.slice(2).join('<br>'),
        list: zones.map(zone => zone.split('|').slice(2).join('|'))
      }
    }
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
          ash_fall: 'ash fall risk zones',
          lahar_flow: 'lahar flow risk zones',
          lava_flow: 'lava flow risk zones'
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
        // message is a feature row
        this.queryFeature = message.split('|')[0]

        grass(this.mapset, `v.extract input=${this.zonesLayer} where="cat = ${this.queryFeature}" output=${queryZone} --overwrite`)

        return this.message3()
      }

      case 'cotopaxi_scenarios.3': {
        // message is a layer name
        this.selectLayer = message

        // Select features from the layer using the query zone
        grass(this.mapset, `v.select ainput=${this.selectLayer} binput=${queryZone} output=${queryResult} operator=overlap --overwrite`)

        // Print results
        console.log(grass(this.mapset, `v.out.ascii input=${queryResult}`))

        return messages[4]
      }
    }
  }

  getQueryableDatasets() {
    return this.datasets.filter(d => !d.match(/cotopaxi_scenarios.*|(ash_fall|lahar_flow|lava_flow)_zones|(lines|points|polygons|relations)_osm/))
  }
}
