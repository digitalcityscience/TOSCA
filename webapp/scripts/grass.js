const fs = require('fs')
const path = require('path')
const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html
const { filterDefaultLayers } = require('./helpers')

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GRASS = process.env.GRASS_DIR

/**
 * Overwrite the region of the given mapset. If no such mapset exists, create it
 * @param {string} mapset mapset
 */
function initMapset(mapset) {
  if (!fs.existsSync(`${GRASS}/global/${mapset}`)) {
    fs.mkdirSync(`${GRASS}/global/${mapset}`)
  }
  fs.copyFileSync(`${GRASS}/global/PERMANENT/WIND`, `${GRASS}/global/${mapset}/WIND`)

  for (const file of fs.readdirSync(`${GRASS}/skel`)) {
    fs.copyFileSync(`${GRASS}/skel/${file}`, `${GRASS}/global/${mapset}/${file}`)
  }
}

/**
 * Import an OSM map file into a GRASS mapset
 * @param {string} mapset mapset
 * @param {string} infile file to import
 * @param {string} layer layer name
 * @param {string} outfile output filename
 */
function addOsm(mapset, infile, layer, outfile) {
  grass(mapset, `v.in.ogr -o input="${infile}" layer="${layer}" output="${outfile}" --overwrite`)
}

/**
 * Import a raster map file into a GRASS mapset
 * @param {string} mapset mapset
 * @param {string} infile file to import
 * @param {string} outfile output filename
 */
function addRaster(mapset, infile, outfile) {
  grass(mapset, `r.import input="${infile}" output="${outfile}" --overwrite`)
}

/**
 * Import a vector map file into a GRASS mapset
 * @param {string} mapset mapset
 * @param {string} infile file to import
 * @param {string} outfile output filename
 * @param {string} layer map layer to be imported - only for multi-layer files
 */
function addVector(mapset, infile, outfile, layer) {
  if (layer) {
    grass(mapset, `v.import input="${infile}" layer="${layer}" output="${outfile}" --overwrite`)
  } else {
    grass(mapset, `v.import input="${infile}" output="${outfile}" --overwrite`)
  }
}

/**
 * Get all layers contained in map file
 * @param {string} mapset mapset
 * @param {string} mapFile map file name
 */
function getLayers(mapset, mapFile) {
  const raw = grass(mapset, `v.import -l input=${mapFile}`)
  const index = raw.lastIndexOf(':')
  return raw.substring(index + 1).split('\n').filter(row => row.length)
}

/**
 * Clip a map layer using the bounds of another layer
 * @param {string} mapset mapset
 * @param {string} layer the layer to clip
 * @param {string} clipLayer the layer whose bounds are used for clipping
 * @param {string} outfile output filename
 */
function clip(mapset, layer, clipLayer, outfile) {
  grass(mapset, `v.clip input=${layer} clip=${clipLayer} output=${outfile} --overwrite`)
}

/**
 * Get the center coordinates of the current selection
 * @param {string} mapset mapset
 * @returns {[number, number]} center coordinates (east, north)
 */
function getCoordinates(mapset) {
  let list = grass(mapset, `g.list type=vector`).trim()
  let region

  if (list.split('\n').indexOf('selection') > -1) {
    region = grass(mapset, `g.region -cg vector=selection`).trim()
  } else {
    region = grass(mapset, `g.region -cg vector=polygons_osm`).trim()
  }

  return [
    region.split('\n')[0].split('=')[1],
    region.split('\n')[1].split('=')[1]
  ]
}

/**
 * Get a layer's attribute columns
 * @param {string} mapset mapset
 * @param {string} layer layer name
 */
function getColumns(mapset, layer) {
  return grass(mapset, `db.describe -c table=${layer}`).trim().split('\n')
    .filter(line => line.match(/^Column/))
    .map(line => {
      const matches = line.match(/Column \d+: ([^:]+):([^:]+):(\d+)/)
      return {
        name: matches[1],
        type: matches[2],
        width: matches[3]
      }
    })
    .filter(col => col.name !== 'cat')
}

/**
 * Get a layer's columns with INTEGER or DOUBLE PRECISION type
 * @param {string} mapset mapset
 * @param {string} layer layer to analyze
 */
function getNumericColumns(mapset, layer) {
  try {
    return grass(mapset, `db.describe -c table=${layer}`).trim().split('\n').filter(col => col.match(/DOUBLE PRECISION|INTEGER/) && !col.match(/cat/i))
  } catch (err) {
    return []
  }
}

/**
 * Returns all columns and their type of a table
 * @param {string} mapset mapset
 * @param {string} layer layer to analyze
 * @return {object} [{'column':'','type':''},{},{},...]
 */
function getAllColumns(mapset, layer) {
  try {
    return grass(mapset, `db.describe -c table=${layer}`)
      .trim()
      .split('\n')
      .filter(col => col.match(/Column/) && !col.match(/cat/i))
      .map(line => ({
        column: line.split(':')[1].trim(),
        type: line.split(':')[2].trim(),
        description: ''
      }))
  } catch (err) {
    return []
  }
}

/**
 * Returns univariate statistics on selected table column for a GRASS vector map
 * @param {string} mapset mapset
 * @param {string} map map
 * @param {string} column column
 */
function getUnivar(mapset, map, column) {
  // when all values are null, v.univar returns some info, but v.db.univar throws error
  return grass(mapset, `v.univar -e -g map=${map} column=${column}`).trim().split('\n')
    .reduce((dict, line) => {
      const a = line.split('=')
      dict[a[0]] = a[1]
      return dict
    }, {})
}

/**
 * Returns min and max value of a univariate stat on selected table column for a GRASS vector map
 * @param {string} mapset mapset
 * @param {string} map map
 * @param {string} column column
 */
function getUnivarBounds(mapset, map, column) {
  const round = (val, n) => {
    let i = 0
    let dot = false
    while (val[i] && ['0', '.'].indexOf(val[i]) > -1) {
      if (val[i] === '.') dot = true
      i++
    }
    if (!dot) {
      while (val[i] && val[i] != '.') i++
    }
    return val.substring(0, i + n + 1)
  }
  const stats = getUnivar(mapset, map, column)
  // stats.n is the number of valid(not NULL) values
  return stats.n > 0 ? [round(stats.min, 2), round(stats.max, 2)] : ['not provided', 'not provided']
}

/**
 * Return a list containing a set of distinct values for each column
 * @param {string} mapset mapset
 * @param {string} layer layer name
 */
function getValueSetsDB(mapset, layer) {
  return getColumns(mapset, layer).map(col => {
    const values = grass(mapset, `db.select sql="SELECT ${col.name} FROM ${layer}"`).trim().split('\n').slice(1)
    col.rows = Array.from(new Set(values).values())
    return col
  })
}

/**
 * Return a list containing a set of distinct values for each column
 * @param {string} mapset mapset
 * @param {string} layer layer name
 */
function getValueSetsVector(mapset, layer) {
  const table = grass(mapset, `v.db.select map=${layer}`).trim().split('\n').map(row => row.split('|'))
  const columns = table[0]
  const rows = table.slice(1)

  return columns.slice(1).map((columnName, i) => {  // ignore first element "cat"
    return {
      name: columnName,
      rows: Array.from(new Set(rows.map(row => row.slice(1)[i])).values())
    }
  })
}

/**
 * select all entries in a table and return the raw bash string
 * @param {string} mapset mapset
 * @param {string} table table to select from
 * @returns {string} all entries
 */
function dbSelectAllRaw(mapset, table) {
  return grass(mapset, `db.select -v sql="select * from ${table}" vertical_separator=space`)
}

/**
 * get all tables in the mapset
 * @param {string} mapset mapset
 * @returns {array} all tables
 */
function dbTables(mapset) {
  const tables = grass(mapset, 'db.tables -p').trim().split('\n')
  return tables
}

/**
 * select all entries in a table and return an object
 * @param {string} mapset mapset
 * @param {string} table table to select from
 * @returns {object[]} array of all entries
 */
function dbSelectAllObj(mapset, table) {
  return dbSelectAllRaw(mapset, table)
    .split(' \n')
    .map(item => item
      .split('\n')
      .filter(row => row.length)
      .reduce((obj, row) => {
        const [key, val] = row.split('|').map(i => i.trim())
        obj[key] = val
        return obj
      }, {})
    )
}

/**
 * Identify the topology of a vector map
 * @param {string} mapset mapset
 * @param {string} layer layer name
 * @returns {string} topology type (possible values are: point, line, area, mixed, empty)
 */
function getTopology(mapset, layer) {
  const info = grass(mapset, `v.info -t map=${layer}`).trim().split('\n').reduce((dict, line) => {
    const a = line.split('=')
    dict[a[0]] = a[1]
    return dict
  }, {})

  return info.points ? (info.lines || info.centroids ? 'mixed' : 'point') : info.lines ? (info.centroids ? 'mixed' : 'line') : info.centroids ? 'area' : 'empty'
}

/**
 * Export a vector map as a GeoPackage file in the GeoServer data directory
 * @param {string} mapset mapset
 * @param {string} infile file to import
 * @param {string} outfile output filename
 */
function gpkgOut(mapset, infile, outfile) {
  grass(mapset, `v.out.ogr format=GPKG input="${infile}" output="${GEOSERVER}/${outfile}.gpkg" --overwrite`)
}

/**
 * List available vector maps
 * @param {string} mapset mapset
 * @return {string[]} names of available maps
 */
function listVector(mapset) {
  return grass(mapset, `g.list -m type=vector`).trim().split('\n')
}

/**
 * List all user uploaded vector maps
 * @return {string[]} names of available maps
 */
function listUserVector() {
  // '-m' guarantees to return fully-qualified map names
  // without '-m', only a part of the names are fully-qualified
  return grass('PERMANENT', 'g.list -m type=vector').trim().split('\n').filter(filterDefaultLayers)
}

/**
 * Checks if the name contains only allowed characters for GRASS mapsets and columns
 * @param {string} name mapset name
 * @return {boolean} true or false
 */
function isLegalName(name) {
  if (!name.length || name[0] === '.') {
    throw new Error(`Illegal filename ${name}. Cannot be 'NULL' or start with '.'.`)
  }
  for (let i = 0; i < name.length; i++) {
    if (['/', '"', '\\', '\'', '@', ',', '=', '*', '~'].indexOf(name[i]) > -1 || name.charCodeAt(i) >= 127 || name[i] <= ' ') {
      throw new Error(`Illegal filename ${name}. Cannot contain symbol '${name[i]}'.`)
    }
  }
  return true
}

/**
 * Check if a mapset exists
 * @param {string} mapset mapset
 * @returns {boolean} true if mapset exists
 */
function mapsetExists(mapset) {
  let exists = true
  try {
    grass(mapset, `g.list type=vector`)
  } catch (err) {
    exists = false
  }
  return exists
}

/**
 * Remove a map layer
 * @param {string} mapset mapset
 * @param {string} layer layer name
 */
function remove(mapset, layer) {
  grass(mapset, `g.remove -f type=vector name=${layer}`)
}

/**
 * Prints all attribute descriptions of a table
 * @param {string} mapset mapset
 * @param {string} table table
 */
function getMetadata(mapset, table) {
  const data = {
    tableObj: { table: table, description: '' },
    columnObj: {
      headFields: ['column', 'type', 'description', 'min', 'max'],
      rows: getAllColumns(mapset, table)
    }
  }

  // set bounds
  for (const row of data.columnObj.rows) {
    let bounds = ['-', '-']
    if (['DOUBLE PRECISION', 'INTEGER'].indexOf(row.type) > -1) {
      bounds = getUnivarBounds(mapset, table, row.column)
    }
    row.min = bounds[0]
    row.max = bounds[1]
  }

  // add descriptions from metadata.json
  let metadata
  try {
    metadata = require(path.resolve(process.cwd(), `${GRASS}/metadata/metadata.json`))
  } catch (err) {
    // TODO: in later version this will be shown as a warning
    console.error('metadata.json not found.')
  }

  if (!metadata || metadata.length === 0) {
    return JSON.stringify(data)
  }
  const meta = metadata.filter(m => m.table === table)[0]
  if (!meta) {
    return JSON.stringify(data)
  }
  data.tableObj.description = meta.description ? meta.description : ''
  data.columnObj.rows.forEach(row => {
    const data = meta.columns.filter(c => c.column === row.column)[0]
    if (data) {
      row.description = data.description
    }
  })

  return JSON.stringify(data)
}

/**
 * Run any GRASS command on a given mapset
 * @param {string} mapset mapset
 * @param {string} args arguments to the command line
 */
function grass(mapset, args) {
  return execSync(`grass "${GRASS}/global/${mapset}" --exec ${args}`, {
    shell: '/bin/bash',
    maxBuffer: 64 * 1024 * 1024,
    encoding: 'utf-8'
  })
}

module.exports = {
  addOsm,
  addRaster,
  addVector,
  clip,
  dbSelectAllObj,
  dbSelectAllRaw,
  dbTables,
  getAllColumns,
  getColumns,
  getCoordinates,
  getLayers,
  getMetadata,
  getNumericColumns,
  getTopology,
  getUnivar,
  getUnivarBounds,
  getValueSetsDB,
  getValueSetsVector,
  gpkgOut,
  grass,
  initMapset,
  listUserVector,
  isLegalName,
  listVector,
  mapsetExists,
  remove
}
