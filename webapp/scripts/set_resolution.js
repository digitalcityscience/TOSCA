const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html

const VARIABLES = `./variables`

const messages = {
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

class SetResolutionModule {
  launch() {
    return messages[1]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'set_resolution.1':
      case 'set_resolution.2': {
        const RESOLUTION = parseInt(message)
        console.log('RESOLUTION:', RESOLUTION)

        if (RESOLUTION <= 0) {
          return messages[2]
        } else {
          execSync(`echo "First data: Resolution in meters, given by the user." > ${VARIABLES}/resolution`)
          execSync(`echo "Second data: resolution in decimal degrees, derivated from first data." >> ${VARIABLES}/resolution`)
          execSync(`echo "${RESOLUTION}" >> ${VARIABLES}/resolution`)
          execSync(`echo "${RESOLUTION/111322}" >> ${VARIABLES}/resolution`)

          return messages[3]
        }
      }
    }
  }
}

module.exports = SetResolutionModule
