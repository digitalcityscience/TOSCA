const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html
const fs = require('fs')

const { addOsm, getCoordinates, gpkgOut, mapsetExists } = require('./functions')

const BROWSER = process.env.DATA_FROM_BROWSER_DIR
const GRASS = process.env.GRASS_DIR
const VARIABLES = `./variables`
const MAPSET = 'module_1'

class ModuleOne {
    constructor() {
        this.messages = {
            0: {
                message_id: 'module_1.0',
                message: "No valid location found. Run Location selector to create a valid location. Module is now exiting."
            },
            1: {
                message_id: 'module_1.1',
                message: { "text": "Start points are required. Do you want to draw start points on the basemap now? If yes, click Yes, then draw one or more point and click Save button. If you want to use an already existing map, select No." }
            },
            2: {
                message_id: 'module_1.2',
                message: { "text": "Select a map (only point maps are supported). Avilable maps are:" }
            },
            3: {
                message_id: 'module_1.3',
                message: { "text": "Via points are optional. If you want to select 'via' points from the map, click Yes. If you want to use an already existing map, select No. If you do not want to use via points, click Cancel." }
            },
            4: {
                message_id: 'module_1.4',
                message: { "text": "Select a map to add to CityApp. Map has to be in Open Street Map format -- osm is the only accepted format." }
            },
            5: {
                message_id: 'module_1.5',
                message: { "text": "Target points are required. If you want to select target points from the map, click Yes. If you want to use an already existing map containing target points, click No. If you want to use the default target points map, click Cancel." }
            },
            6: {
                message_id: 'module_1.6',
                message: { "text": "Select a map (only point maps are supported). Available maps are:" }
            },
            7: {
                message_id: 'module_1.7',
                message: { "text": "Optionally you may define stricken area. If you want to draw area on the map, click Yes. If you want to select a map already containing area, click No. If you do not want to use any area, click Cancel." }
            },
            8: {
                message_id: 'module_1.8',
                message: { "text": "Select a map (only area maps are supported)" }
            },
            9: {
                message_id: 'module_1.9',
                message: { "text": "Do you want to set the speed on the road network? If not, the current values will be used." }
            },
            10: {
                message_id: 'module_1.10',
                message: { "text": "Set speed reduction ratio for roads of stricken area. This must be a number greater than 0 and less than 1." }
            },
            11: {
                message_id: 'module_1.11',
                message: { "text": "Calculations are ready. Display output time maps." }
            }
        }
    }

    launch() {
        try {
            if (fs.existsSync(`${GRASS}/global/${MAPSET}`)) {
                execSync(`cp "${GRASS}"/global/PERMANENT/WIND "${GRASS}"/global/"${MAPSET}"/WIND`)
            }
            else {
                execSync(`mkdir "${GRASS}"/global/"${MAPSET}"`)
                execSync(`cp "${GRASS}"/global/PERMANENT/WIND "${GRASS}"/global/"${MAPSET}"/WIND`)
                execSync(`cp -r ~/cityapp/grass/skel/* "${GRASS}"/global/"${MAPSET}"`) // question: there's only "~/cityapp/grass/skel_permanent/"
            }
        } catch (err) {
            console.error(err)
        }

        // EAST=$(cat $VARIABLES/coordinate_east) // question: what is this for?
        // NORTH=$(cat $VARIABLES/coordinate_north)

        // # Creating empty maps for ps output, if no related maps are created/selected by user: // question: what is this for?
        // # m1_via_points m1_to_points, m1_stricken_area
        // # If user would create a such map, empty maps will automatically overwritten
        // v.edit map=m1_via_points tool=create
        // v.edit map=m1_to_points tool=create
        // v.edit map=m1_stricken_area tool=create

        if (mapsetExists('PERMANENT')) {
            return this.messages[1]
        }
        return this.messages[6]
    }

    process(message, replyTo) {
        switch (replyTo) {
            case 'module_1.1':
                if (message.toLowerCase() == 'no') {
                    return this.messages[2]
                }
            case 'module_1.2':
                return this.messages[3]
            case 'module_1.3':
                if (message.toLowerCase() == 'no') {
                    return this.messages[5]
                }
            case 'module_1.3':
                if (message.toLowerCase() == 'no') {
                    return this.messages[4]
                }
                else if (message.toLowerCase() == 'cancel') {
                    return this.messages[5]
                }
            case 'module_1.4':
                return this.messages[5]
            case 'module_1.5':
                if (message.toLowerCase() == 'no') {
                    return this.messages[6]
                }
                else if (message.toLowerCase() == 'cancel') {
                    return this.messages[7]
                }
            case 'module_1.6':
                return this.messages[7]
            case 'module_1.7':
                if (message.toLowerCase() == 'no') {
                    return this.messages[8]
                }
                else if (message.toLowerCase() == 'cancel') {
                    return this.messages[9]
                }
            case 'module_1.8':
                return this.messages[9]
            case 'module_1.9':
                if (message.toLowerCase() == 'yes') {
                    return this.messages[10]
                }
                else if (message.toLowerCase() == 'no') {
                    return this.messages[11]
                }
            case 'module_1.10':
                return this.messages[11]

        }
    }
    processFile(filename, replyTo) {
        console.log('replyTo: ', replyTo)
        switch (replyTo) {
            /**
             * TODO: draw start point
             */
            case 'module_1.1':
                return this.messages[3]
            /**
             * TODO: draw via points
             */
            case 'module_1.3':
                return this.messages[5]
            /**
             * TODO: draw target points
             */
            case 'module_1.5':
                return this.messages[7]
            /**
             * TODO: draw stricken area
             */
            case 'module_1.7':
                return this.messages[9]
        }
    }
}

module.exports = ModuleOne
