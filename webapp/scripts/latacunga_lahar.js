const { addVector, initMapset, mapsetExists } = require('./functions')

const messages = {
  "1": {
    "message_id": "latacunga_lahar.1",
    "message": {
      "text": "Before you can use this module, you must add a map layer containing the lahar risk zones. Please select a file (.gpkg) to upload."
    }
  },
  "2": {
    "message_id": "latacunga_lahar.2",
    "message": {
      "text": "Choose a map layer on which you want to calculate the effects.<br><br>[file upload OR selection of added maps]"
    }
  },
}

module.exports = class {
  constructor() {
    this.mapset = 'latacunga_lahar'
  }

  launch() {
    if (!mapsetExists(this.mapset)) {
      return messages[1]
    }

    return messages[2]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'latacunga_lahar.1': {
        // uploaded file
        if (!message.match(/\.gpkg$/i)) {
          throw new Error("Wrong file format - must be GeoPackage (.gpkg)")
        }

        initMapset('latacunga_lahar')

        addVector(this.mapset, message, 'lahar_risk_zones')

        return messages[2]
      }

    }
  }

}
