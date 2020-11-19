const fs = require('fs')
const { checkWritableDir, getAllColumns, getTopology, gpkgOut, initMapset, grass, mapsetExists, mergePDFs, psToPDF, textToPS, remove, getUnivar, getUnivarBounds, getFilesOfType, listUserVector, addVector, getLayers, dbSelectAll } = require('./functions')
const { query: messages } = require('./messages.json')

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const CONTAINER_GEOSERVER = '/usr/share/geoserver/data_dir/data'
const GRASS = process.env.GRASS_DIR
const OUTPUT = process.env.OUTPUT_DIR

const QUERY_RESOLUTION = 0.00002
const QUERY_MAP_NAME = 'query_map'
const QUERY_RESULT_NAME = 'query_result'

module.exports = class {
  constructor() {
    this.mapset = 'query'
  }

  launch() {
    checkWritableDir(GEOSERVER)
    checkWritableDir(OUTPUT)

    if (!mapsetExists('PERMANENT')) {
      return messages["7"]
    }

    initMapset(this.mapset)

    // set selection as the query area
    grass(this.mapset, `g.copy vector=selection@PERMANENT,selection --overwrite`)
    this.queryArea = 'selection'

    const allVector = listUserVector()
    const allGpkg = getFilesOfType('gpkg', CONTAINER_GEOSERVER)
      .filter(map => !map.match(/((lines|points|polygons|relations)(_osm)?|selection|location_bbox)(@.+)?/))

    /**
     * check and add all layers from layer switcher
     * FIXME: mapFile name and layer name differs, which makes it hard to check if file has already been imported 
     * ideal solution: 1. make sure all map files contains only one layer; 2. make sure all mapFile names align with its layer's name
     */
    for (const mapFile of allGpkg) {
      const fileName = mapFile.slice(mapFile.lastIndexOf('/') + 1, mapFile.lastIndexOf('.'))
      if (allVector.indexOf(fileName) > -1) continue

      const inLayers = getLayers('PERMANENT', mapFile)
      // GRASS doesn't allow space in layernames
      const grassLayers = inLayers.map(layer => layer.replace(' ', '_'))
      // single-layered mapFiles
      if (inLayers.length === 1) {
        // using mapFile name as GRASS layer name for single-layered mapFiles
        addVector('PERMANENT', mapFile, fileName)
      }
      // multi-layered mapFiles 
      else if (inLayers.length > 1) {
        grassLayers.forEach((gLayer, i) => {
          // check if this layer has already been imported
          if (allVector.indexOf(gLayer) < 0) {
            // using layer name in original mapFile as GRASS layer name
            addVector('PERMANENT', mapFile, gLayer, inLayers[i])
          }
        })
      }
    }

    const msg = messages["2"]
    msg.message.list = listUserVector()
    return msg
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'query.2': {
        this.mapToQuery = message

        // remove old query_map
        remove(this.mapset, QUERY_MAP_NAME)

        // Now it is possible to check if the map to query is in the default mapset 'query' or not. If not, the map has to be copied into the query mapset.
        if (grass('PERMANENT', `g.list type=vector mapset=${this.mapset}`).split('\n').indexOf(this.mapToQuery) == -1) {
          grass(this.mapset, `g.copy vector=${this.mapToQuery}@PERMANENT,${QUERY_MAP_NAME}`)
        } else {
          grass(this.mapset, `g.copy vector=${this.mapToQuery}@${this.mapset},${QUERY_MAP_NAME}`)
        }

        gpkgOut(this.mapset, QUERY_MAP_NAME, QUERY_MAP_NAME)

        // query map topology
        getTopology(this.mapset, QUERY_MAP_NAME)

        const cols = getAllColumns(this.mapset, QUERY_MAP_NAME)
        const vals = dbSelectAll(this.mapset, QUERY_MAP_NAME)
        cols.forEach(column => {
          // if column is numeric, get bounds
          if (['DOUBLE PRECISION', 'INTEGER'].indexOf(column.type) > -1) {
            const bds = getUnivarBounds(this.mapset, QUERY_MAP_NAME, column.column)
            if (bds.length) column['bounds'] = bds
          }
          // if column is text, get values
          else {
            column.vals = [...new Set(vals.map(c => c[column.column]))]
          }
        })
        const msg = messages["3"]
        msg.message.list = cols
        msg.message.map = this.mapToQuery
        return msg
      }

      case 'query.3': {
        const where = message.reduce((sum, msg) => sum + msg.where + ' ', '').trim()
        this.calculate(message, where)
        return messages["24"]
      }
    }
  }

  calculate(message, where) {
    // remove old query_result
    remove(this.mapset, QUERY_RESULT_NAME)

    // Set region to query area, set resolution
    grass(this.mapset, `g.region vector=${QUERY_MAP_NAME} res=${QUERY_RESOLUTION} --overwrite`)

    // Set mask to query area
    grass(this.mapset, `r.mask vector=${this.queryArea} --overwrite`)

    // Clip the basemep map by query area
    grass(this.mapset, `v.select ainput=${QUERY_MAP_NAME} atype=point,line,boundary,centroid,area binput=${this.queryArea} btype=area output=clipped_1 operator=overlap --overwrite`)

    // Apply the query request
    grass(this.mapset, `v.extract input=clipped_1 where="${where}" output=${QUERY_RESULT_NAME} --overwrite`)

    // // FIXME: if the part from line 151 can be removed, the stats can also be removed
    // // TODO: handle output when query_result is empty
    // // Query statistics
    // const stats = getUnivar(this.mapset, QUERY_RESULT_NAME, queryColumn)
    // Data output
    gpkgOut(this.mapset, QUERY_RESULT_NAME, QUERY_RESULT_NAME)

    const date = new Date()
    const dateString = date.toString()
    const safeDateString = date.toISOString().replace(/([\d-]*)T(\d\d):(\d\d):[\d.]*Z/g, '$1_$2$3')

    let output = `Statistics and map results

Date of creation: ${dateString}
Queried columns: ${message.map(msg => msg.column).toString()}
Criteria: ${where}`
// FIXME: this part below does not really make sense to the user. my suggestion is to delete it...
// Results:
// Number of features:          ${stats.n}
// Sum of values:               ${stats.sum}
// Minimum value:               ${stats.min}
// Maximum value:               ${stats.max}
// Range of values:             ${stats.range}
// Mean:                        ${stats.mean}
// Mean of absolute values:     ${stats.mean_abs}
// Median:                      ${stats.median}
// Standard deviation:          ${stats.stddev}
// Variance:                    ${stats.variance}
// Relative standard deviation: ${stats.coeff_var}
// 1st quartile:                ${stats.first_quartile}
// 3rd quartile:                ${stats.third_quartile}
// 90th percentile:             ${stats.percentile_90}`

    // Generate PDF

    fs.mkdirSync('tmp', { recursive: true })
    fs.writeFileSync('tmp/statistics_output', output)

    textToPS('tmp/statistics_output', 'tmp/statistics.ps')
    psToPDF('tmp/statistics.ps', 'tmp/statistics.pdf')

    grass(this.mapset, `ps.map input="${GRASS}/variables/defaults/query.ps_param" output=tmp/query_map.ps --overwrite`)
    psToPDF('tmp/query_map.ps', 'tmp/query_map.pdf')

    mergePDFs(`${OUTPUT}/query_results_${safeDateString}.pdf`, 'tmp/statistics.pdf', 'tmp/query_map.pdf')

    fs.rmdirSync('tmp', { recursive: true })

    return output
  }

}
