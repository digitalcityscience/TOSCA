const fs = require('fs')

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
    if (replyTo == 'set_resolution.1' || replyTo == 'set_resolution.2') {
      const resolution = parseInt(message)

      if (resolution <= 0) {
        return this.messages[2]
      } else {
        // [0] resolution in meters as given by the user
        // [1] resolution in decimal degrees, derived from resolution in meters
        const data = [resolution, resolution/111322]
        fs.writeFileSync(`${GRASS}/variables/resolution`, data.join("\n"))

        return this.messages[3]
      }
    }
  }
}

module.exports = SetResolutionModule
