const fs = require('fs')
const { checkWritableDir, getNumericColumns, getTopology, gpkgOut, initMapset, grass, mapsetExists, mergePDFs, psToPDF, textToPS, remove, getUnivar, getUnivarBounds, getAllFile, listUserVector, addVector } = require('./functions')
const { module_2: messages } = require('./messages.json')

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const CONTAINER_GEOSERVER = '/usr/share/geoserver/data_dir/data'
const GRASS = process.env.GRASS_DIR
const OUTPUT = process.env.OUTPUT_DIR

const QUERY_RESOLUTION = 0.00002
const QUERY_MAP_NAME = 'query_map'
const QUERY_RESULT_NAME = 'query_result'

class ModuleTwo {
  constructor() { }

  launch() {
    checkWritableDir(GEOSERVER)
    checkWritableDir(OUTPUT)

    if (!mapsetExists('PERMANENT')) {
      return messages["7"]
    }

    initMapset('module_2')

    // set selection as the query area
    grass('module_2', `g.copy vector=selection@PERMANENT,selection --overwrite`)
    this.queryArea = 'selection'

    const allVector = listUserVector()
    // check and add all layers from layer switcher
    getAllFile(CONTAINER_GEOSERVER, [], 'gpkg').forEach(mapFile => {
      if (allVector.indexOf(mapFile.slice(mapFile.lastIndexOf('/') + 1, mapFile.lastIndexOf('.'))) < 0) {
        try {
          addVector('PERMANENT', mapFile, mapFile.slice(mapFile.lastIndexOf('/') + 1, mapFile.lastIndexOf('.')))
        } catch (e) {
          console.error(`failed to import ${mapFile} due to error: ${e}`)
        }
      }
    })

    // Find queryable maps in any mapset, excluding default basemaps and selection.
    // Only maps with at least one numeric column will be listed.
    let maps = listUserVector()
      .filter(map => getNumericColumns('PERMANENT', map).length > 0)

    const msg = messages["2"]
    msg.message.list = maps
    return msg
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'module_2.2': {
        this.mapToQuery = message

        // remove old query_map
        remove('module_2', QUERY_MAP_NAME)

        // Now it is possible to check if the map to query is in the default mapset 'module_2' or not. If not, the map has to be copied into the module_2 mapset.
        if (grass('PERMANENT', `g.list type=vector mapset=module_2`).split('\n').indexOf(this.mapToQuery) == -1) {
          grass('module_2', `g.copy vector=${this.mapToQuery}@PERMANENT,${QUERY_MAP_NAME}`)
        } else {
          grass('module_2', `g.copy vector=${this.mapToQuery}@module_2,${QUERY_MAP_NAME}`)
        }

        gpkgOut('module_2', QUERY_MAP_NAME, QUERY_MAP_NAME)

        // query map topology
        getTopology('module_2', QUERY_MAP_NAME)

        // get value bounds of all numeric columns
        const columns = getNumericColumns('module_2', QUERY_MAP_NAME).map(line => line.split(':')[1].trim())
        const list = []
        columns.forEach(column => {
          list.push({ 'column': column, 'bounds': getUnivarBounds('module_2', QUERY_MAP_NAME, column) })
        })
        const msg = messages["3"]
        msg.message.list = list
        msg.message.map = this.mapToQuery
        return msg
      }

      case 'module_2.3': {
        const where = message.reduce((sum, el) => sum + el + ' ', '').trim()
        this.calculate(message[0], where)
        return messages["24"]
      }
    }
  }

  calculate(queryColumn, where) {
    // remove old query_result
    remove('module_2', QUERY_RESULT_NAME)

    // Set region to query area, set resolution
    grass('module_2', `g.region vector=${QUERY_MAP_NAME} res=${QUERY_RESOLUTION} --overwrite`)

    // Set mask to query area
    grass('module_2', `r.mask vector=${this.queryArea} --overwrite`)

    // Clip the basemep map by query area
    grass('module_2', `v.select ainput=${QUERY_MAP_NAME} atype=point,line,boundary,centroid,area binput=${this.queryArea} btype=area output=clipped_1 operator=overlap --overwrite`)

    // Apply the query request
    grass('module_2', `v.extract input=clipped_1 where="${where}" output=${QUERY_RESULT_NAME} --overwrite`)

    // TODO: handle output when query_result is empty
    // Query statistics
    const stats = getUnivar('module_2', QUERY_RESULT_NAME, queryColumn)
    // Data output
    gpkgOut('module_2', QUERY_RESULT_NAME, QUERY_RESULT_NAME)

    const date = new Date()
    const dateString = date.toString()
    const safeDateString = date.toISOString().replace(/([\d-]*)T(\d\d):(\d\d):[\d.]*Z/g, '$1_$2$3')

    let output = `Statistics and map results

Date of creation: ${dateString}
Queried column: ${queryColumn}
Criteria: ${where}
Results:
Number of features:          ${stats.n}
Sum of values:               ${stats.sum}
Minimum value:               ${stats.min}
Maximum value:               ${stats.max}
Range of values:             ${stats.range}
Mean:                        ${stats.mean}
Mean of absolute values:     ${stats.mean_abs}
Median:                      ${stats.median}
Standard deviation:          ${stats.stddev}
Variance:                    ${stats.variance}
Relative standard deviation: ${stats.coeff_var}
1st quartile:                ${stats.first_quartile}
3rd quartile:                ${stats.third_quartile}
90th percentile:             ${stats.percentile_90}`

    // Generate PDF

    fs.mkdirSync('tmp', { recursive: true })
    fs.writeFileSync('tmp/statistics_output', output)

    textToPS('tmp/statistics_output', 'tmp/statistics.ps')
    psToPDF('tmp/statistics.ps', 'tmp/statistics.pdf')

    grass('module_2', `ps.map input="${GRASS}/variables/defaults/module_2.ps_param_1" output=tmp/query_map.ps --overwrite`)
    psToPDF('tmp/query_map.ps', 'tmp/query_map.pdf')

    mergePDFs(`${OUTPUT}/query_results_${safeDateString}.pdf`, 'tmp/statistics.pdf', 'tmp/query_map.pdf')

    fs.rmdirSync('tmp', { recursive: true })

    return output
  }

}

module.exports = ModuleTwo
