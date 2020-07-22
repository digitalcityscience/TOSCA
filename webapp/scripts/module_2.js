const { addVector, getNumericColumns, getTopology, gpkgOut, initMapset, grass } = require('./functions')

class ModuleTwo {
  constructor() {
    this.messages = {
      1: {
        message_id: 'module_2.1',
        message: { "text": "Draw an area to query." }
      },
      2: {
        message_id: 'module_2.2',
        message: { "text": "Which map do you want to query? Available maps are:" }
      },
      3: {
        message_id: 'module_2.3',
        message: { "text": "Fill the form and press save." }
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
        const [queryColumn, whereColumn1, relation1, value1, logical1, whereColumn2, relation2, value2, logical2, whereColumn3, relation3, value3] = message
        const where = `${whereColumn1} ${relation1} ${value1} ${logical1} ${whereColumn2} ${relation2} ${value2} ${logical2} ${whereColumn3} ${relation3} ${value3}`

        console.log(queryColumn)
        console.log(where)
      }
    }
  }

}

module.exports = ModuleTwo
