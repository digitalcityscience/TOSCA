const { addVector, getTopology, gpkgOut, initMapset, grass } = require('./functions')

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
        message: { "text": "Fill the form and press save. Available columns are:" }
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
            .filter(map => grass('PERMANENT', `db.describe -c table=${map}`).trim().split('\n').filter(col => col.match(/DOUBLE PRECISION|INTEGER/)).filter(col => !col.match(/cat/i)).length > 0)

          const msg = this.messages[2]
          msg.message.list = maps
          return msg
        }
        return

      case 'module_2.2':
        this.mapToQuery = message

        // Now it is possible to check if the map to query is in the default mapset 'module_2' or not. If not, the map has to be copied into the module_2 mapset.
        if (grass('module_2', `g.list type=vector`).split('\n').indexOf(this.mapToQuery) == -1) {
          grass('module_2', `g.copy vector=${this.mapToQuery}@PERMANENT,${this.mapToQuery}`)
        }

        // query map topology
        getTopology('module_2', this.mapToQuery)

        return this.messages[3]
    }
  }

}

module.exports = ModuleTwo
