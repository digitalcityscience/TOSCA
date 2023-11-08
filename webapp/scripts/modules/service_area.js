const fs = require('fs')
const { addVector, gpkgOut, grass, initMapset, listVector, mapsetExists, remove } = require('../grass')
const { checkWritableDir, mergePDFs, psToPDF, textToPS } = require('../helpers')
const translations = require(`../../i18n/messages.${process.env.USE_LANG || 'en'}.json`)
const spawn = require('child_process').spawn

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GRASS = process.env.GRASS_DIR
const OUTPUT = process.env.OUTPUT_DIR

module.exports = class {
    constructor(){
        this.mapset = 'service_area'
    }

    launch(){
        checkWritableDir(GEOSERVER)
        checkWritableDir(OUTPUT)

        if (!mapsetExists('PERMANENT')) {
            return { id: 'time_map.7', message: translations['time_map.message.7'] }
          }
      
        initMapset(this.mapset)

        return {id: "service_area.1", message: translations['service_area.1']}
    }

    process(message, replyTo){
        switch(replyTo){
            // Read type of input
            case 'service_area.1' :{

                if(message === "Select point"){
                    return {id: 'service_area.3', message: translations['service_area.3']}
                }
                else if(message === "Select Layer File"){
                    return {id: 'service_area.4', message: translations['service_area.4']}
                }

            }
            // If drawing is cancelled
            case 'service_area.3':{

                if(message === "cancel"){
                    return {id: 'service_area.6', message: "Process Cancelled"}
                }
                return {id: 'service_area.5', message: translations['service_area.5']}
            }
            // Pass Layer file info for processing
            case 'service_area.4':{
                return {id: 'service_area.5', message: translations['service_area.5'], Layer: message}
            }
            // End Screen Message
            case 'service_area.5':{
                return {id: 'service_area.2', message: translations['service_area.2']}
            }
        }
    }
}