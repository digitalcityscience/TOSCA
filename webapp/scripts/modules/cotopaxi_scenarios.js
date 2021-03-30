const fs = require('fs')
const { addVector, getValueSetsDB, grass, initMapset, listVector, mapsetExists, dbSelectAllRaw, remove, dbTables } = require('../grass')
const { checkWritableDir, filterDefaultLayers, psToPDF, textToPS, mergePDFs } = require('../helpers')
const translations = require(`../../i18n/messages.${process.env.USE_LANG || 'en'}.json`)

const GEOSERVER_DATA_DIR = process.env.GEOSERVER_DATA_DIR
const GRASS_DIR = process.env.GRASS_DIR
const OUTPUT_DIR = process.env.OUTPUT_DIR

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

    if (!mapsetExists('PERMANENT')) {
      return { id: 'query.7', message: translations['query.message.7'] }
    }
    initMapset(this.mapset)

    return { id: 'cotopaxi_scenarios.0', message: translations['cotopaxi_scenarios.message.0'] }
  }

  message2() {
    return {
      id: 'cotopaxi_scenarios.2',
      message: translations['cotopaxi_scenarios.message.2'],
      list: getValueSetsDB(this.mapset, this.zonesLayer)
    }
  }

  message3() {
    return {
      id: 'cotopaxi_scenarios.3',
      message: translations['cotopaxi_scenarios.message.3'],
      list: this.getQueryableDatasets()
    }
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'cotopaxi_scenarios.0': {
        // message should be one of ['ash_fall', 'lahar_flow', 'lava_flow']
        this.typeOfThreat = message
        this.zonesLayer = `${this.typeOfThreat}_zones`

        this.datasets = listVector(this.mapset)

        // If zones layer exists, jump to the next step …
        if (this.datasets.indexOf(`${this.zonesLayer}@${this.mapset}`) > -1) {
          return this.message2()
        }

        // … else request upload of dataset
        return {
          id: 'cotopaxi_scenarios.1',
          message: translations['cotopaxi_scenarios.message.1'].replace(/\$1/, {
            'ash_fall': translations['cotopaxi_scenarios.message.1.1'],
            'lahar_flow': translations['cotopaxi_scenarios.message.1.2'],
            'lava_flow': translations['cotopaxi_scenarios.message.1.3']
          }[this.typeOfThreat])
        }
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
        grass(this.mapset, `v.extract input=${this.zonesLayer} where="${col} = '${val}'" output=${queryZone} --overwrite`)

        return this.message3()
      }

      case 'cotopaxi_scenarios.3': {
        // remove old queryResult
        remove(this.mapset, queryResult)

        // message is a layer name
        this.selectLayer = message

        // Select features from the layer using the query zone
        grass(this.mapset, `v.select ainput=${this.selectLayer} binput=${queryZone} output=${queryResult} operator=overlap --overwrite`)

        // Check if the query result is not empty
        if (dbTables(this.mapset).indexOf(queryResult) === -1) {
          return { id: 'cotopaxi_scenarios.5', message: translations['cotopaxi_scenarios.message.5'] }
        }

        // Copy result into PERMANENT to be used by query module
        grass('PERMANENT', `g.copy vector=${queryResult}@${this.mapset},${queryResult} --overwrite`)

        const date = new Date()
        const dateString = date.toString()
        const safeDateString = date.toISOString().replace(/([\d-]*)T(\d\d):(\d\d):[\d.]*Z/g, '$1_$2$3')
        const  entries = dbSelectAllRaw(this.mapset, queryResult).split(' \n')
        let output = `Statistics and map results

${translations['cotopaxi_scenarios.output.1']}: ${dateString}
${translations['cotopaxi_scenarios.output.2']}: ${this.typeOfThreat}
${translations['cotopaxi_scenarios.output.3']}: ${this.selectLayer}
${translations['cotopaxi_scenarios.output.4']}: ${entries.length - 1}
${translations['cotopaxi_scenarios.output.5']}:
    `

        if (entries.length <= 30) {
          output += entries.join('\n')
        } else {
          output += (entries.slice(0, 30).join('\n') + '\n')
        }

        fs.mkdirSync('tmp', { recursive: true })
        fs.writeFileSync('tmp/statistics_output', output)

        textToPS('tmp/statistics_output', 'tmp/statistics.ps')
        psToPDF('tmp/statistics.ps', 'tmp/statistics.pdf')

        // Set the region for the output map, using the bounds of queryResult
        grass(this.mapset, `g.region vector=${queryResult} --overwrite`)

        // Create PS output
        grass(this.mapset, `ps.map input="${GRASS_DIR}/variables/defaults/cotopaxi_scenarios.ps_param" output=tmp/cotopaxi_scenarios.ps --overwrite`)

        // Convert to PDF
        psToPDF('tmp/cotopaxi_scenarios.ps', 'tmp/cotopaxi_scenarios.pdf')

        this.outfile = `cotopaxi_scenarios_${safeDateString}.pdf`;

        mergePDFs(`${OUTPUT_DIR}/${this.outfile}`, 'tmp/cotopaxi_scenarios.pdf', 'tmp/statistics.pdf')

        fs.rmdirSync('tmp', { recursive: true })

        return {
          id: 'cotopaxi_scenarios.4',
          message: translations['cotopaxi_scenarios.message.4'],
          result: this.outfile
        }
      }
    }
  }

  getQueryableDatasets() {
    return this.datasets
      .filter(filterDefaultLayers)
      .filter(d => !d.match(/cotopaxi_scenarios.*|(ash_fall|lahar_flow|lava_flow)_zones/))
      .map(name => name.split('@')[0])
  }
}
