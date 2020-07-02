const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html

const VARIABLES = `./variables`

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

        console.log('resolution:', resolution)

        if (resolution <= 0) {
          return this.messages[2]
        } else {
          execSync(`echo "First data: Resolution in meters, given by the user." > ${VARIABLES}/resolution`)
          execSync(`echo "Second data: resolution in decimal degrees, derivated from first data." >> ${VARIABLES}/resolution`)
          execSync(`echo "${resolution}" >> ${VARIABLES}/resolution`)
          execSync(`echo "${resolution/111322}" >> ${VARIABLES}/resolution`)

          return this.messages[3]
        }
      }
    }
  }
}

module.exports = SetResolutionModule
