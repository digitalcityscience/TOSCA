const fs = require('fs')
const { addVector, getNumericColumns, getTopology, gpkgOut, initMapset, grass, mergePDFs, psToPDF, textToPS } = require('./functions')

const GRASS = process.env.GRASS_DIR
const OUTPUT = process.env.OUTPUT_DIR

const QUERY_RESOLUTION = 0.00002

class ModuleTwo {
  constructor() {
    this.messages = {
      1: {
        message_id: 'module_2.1',
        message: { text: "Draw an area to query." }
      },
      2: {
        message_id: 'module_2.2',
        message: { text: "Which map do you want to query? Available maps are:" }
      },
      3: {
        message_id: 'module_2.3',
        message: { text: "Fill the form and press save." }
      },
      24: {
        message_id: 'module_2.24',
        message: { text: "Statistics output is ready." }
      }
    }
  }

  launch() {
    initMapset('module_2')

    return this.messages[1]
  }

  process(message, replyTo) {
    switch (replyTo) {
      case 'module_2.1':
        if (message.match(/drawing\.geojson/)) {
          addVector('module_2', message, 'query_area_1')
          gpkgOut('module_2', 'query_area_1', 'query_area_1')
          this.queryArea = 'query_area_1'

          // Only maps of PERMANENT mapset can be queried. Default maps and "selection" map are not included in the list. Only maps with numeric column (except column "CAT") will be listed.
          let maps = grass('PERMANENT', `g.list type=vector`).trim().split('\n')
            .filter(map => !map.match(/^lines(_osm)?$|^points(_osm)?$|^polygons(_osm)?$|^relations(_osm)?$|^selection$/))
            .filter(map => getNumericColumns('PERMANENT', map).length > 0)

          const msg = this.messages[2]
          msg.message.list = maps
          return msg
        }
        return

      case 'module_2.2': {
        this.mapToQuery = message

        // Now it is possible to check if the map to query is in the default mapset 'module_2' or not. If not, the map has to be copied into the module_2 mapset.
        if (grass('PERMANENT', `g.list type=vector mapset=module_2`).split('\n').indexOf(this.mapToQuery) == -1) {
          grass('module_2', `g.copy vector=${this.mapToQuery}@PERMANENT,${this.mapToQuery}`)
        }

        // query map topology
        getTopology('module_2', this.mapToQuery)

        const msg = this.messages[3]
        msg.message.list = getNumericColumns('module_2', this.mapToQuery).map(item => item.split(':')[1].trim())
        return msg
      }

      case 'module_2.3': {
        const where = message.reduce((sum, el)=> sum + el + ' ','').trim()
        this.calculate(message[0], where)
        return this.messages[24]
      }
    }
  }

  calculate(queryColumn, where) {
    // Set region to query area, set resolution
    grass('module_2', `g.region vector=${this.mapToQuery} res=${QUERY_RESOLUTION} --overwrite`)

    // Set mask to query area
    grass('module_2', `r.mask vector=${this.queryArea} --overwrite`)

    // Clip the basemep map by query area
    grass('module_2', `v.select ainput=${this.mapToQuery} atype=point,line,boundary,centroid,area binput=${this.queryArea} btype=area output=clipped_1 operator=overlap --overwrite`)

    // Apply the query request
    grass('module_2', `v.extract input=clipped_1 where="${where}" output=query_result_area_1 --overwrite`)

    // Query statistics
    const stats = grass('module_2', `v.db.univar -e -g map=query_result_area_1 column=${queryColumn}`).trim().split('\n').map(line => line.split('=')[1])

    // Data output
    gpkgOut('module_2', 'query_result_area_1', 'query_result_area_1')

    const date = new Date()
    const dateString = date.toString()
    const safeDateString = date.toISOString().replace(/([\d-]*)T(\d\d):(\d\d):[\d.]*Z/g, '$1_$2$3')

    let output = `Statistics and map results

Date of creation: ${dateString}
Queried column: ${queryColumn}
Criteria: ${where}
Results:
Number of features:          ${stats[0]}
Sum of values:               ${stats[9]}
Minimum value:               ${stats[1]}
Maximum value:               ${stats[2]}
Range of values:             ${stats[3]}
Mean:                        ${stats[4]}
Mean of absolute values:     ${stats[5]}
Median:                      ${stats[11]}
Standard deviation:          ${stats[7]}
Variance:                    ${stats[6]}
Relative standard deviation: ${stats[8]}
1st quartile:                ${stats[10]}
3rd quartile:                ${stats[12]}
90th percentile:             ${stats[13]}`

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
