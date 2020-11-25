const fs = require('fs')
const { checkWritableDir, getNumericColumns, getTopology, gpkgOut, initMapset, grass, mapsetExists, mergePDFs, psToPDF, textToPS, remove, getUnivar, getUnivarBounds } = require('./functions')
const translations = require(`../i18n/messages.${process.env.USE_LANG || 'en'}.json`)

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
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
      return { id: 'query.7', message: translations['query.message.7'] }
    }

    initMapset('module_2')

    // set selection as the query area
    grass('module_2', `g.copy vector=selection@PERMANENT,selection --overwrite`)
    this.queryArea = 'selection'

    // Find queryable maps in any mapset, excluding default basemaps and selection.
    // Only maps with at least one numeric column will be listed.
    let maps = grass('PERMANENT', `g.list type=vector mapset=*`).trim().split('\n')
      .filter(map => !map.match(/^((lines|points|polygons|relations)(_osm)?|selection|location_bbox)(@.+)?$/))
      .filter(map => getNumericColumns('PERMANENT', map).length > 0)

    return {
      id: 'query.2',
      message: translations['query.message.2'],
      list: maps
    }
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'query.2': {
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

        return {
          id: 'query.3',
          message: translations['query.message.3'],
          list: list,
          map: this.mapToQuery
        }
      }

      case 'query.3': {
        const where = message.reduce((sum, el) => sum + el + ' ', '').trim()
        this.calculate(message[0], where)
        return { id: 'query.24', message: translations['query.message.24'] }
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

    let output = `${translations['query.output.1']}

${translations['query.output.2']}: ${dateString}
${translations['query.output.3']}: ${queryColumn}
${translations['query.output.4']}: ${where}
${translations['query.output.5']}:
${translations['query.output.6']}: ${stats.n}
${translations['query.output.7']}: ${stats.sum}
${translations['query.output.8']}: ${stats.min}
${translations['query.output.9']}: ${stats.max}
${translations['query.output.10']}: ${stats.range}
${translations['query.output.11']}: ${stats.mean}
${translations['query.output.12']}: ${stats.mean_abs}
${translations['query.output.13']}: ${stats.median}
${translations['query.output.14']}: ${stats.stddev}
${translations['query.output.15']}: ${stats.variance}
${translations['query.output.16']}: ${stats.coeff_var}
${translations['query.output.17']}: ${stats.first_quartile}
${translations['query.output.18']}: ${stats.third_quartile}
${translations['query.output.19']}: ${stats.percentile_90}`

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
