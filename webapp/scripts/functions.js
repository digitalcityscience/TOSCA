const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html
const fs = require('fs')
const path = require("path")

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GRASS = process.env.GRASS_DIR
const outputDir = process.env.OUTPUT_DIR

module.exports = {
  /**
   * Import an OSM map file into a GRASS mapset.
   * @param {string} mapset
   * @param {string} infile file to import
   * @param {string} layer layer name
   * @param {string} outfile output filename
   */
  addOsm(mapset, infile, layer, outfile) {
    grass(mapset, `v.in.ogr -o input="${infile}" layer="${layer}" output="${outfile}" --overwrite`)
  },

  /**
   * Import a raster map file into a GRASS mapset.
   * @param {string} mapset
   * @param {string} infile file to import
   * @param {string} outfile output filename
   */
  addRaster(mapset, infile, outfile) {
    grass(mapset, `r.import input="${infile}" output="${outfile}" --overwrite`)
  },

  /**
   * Import a vector map file into a GRASS mapset.
   * @param {string} mapset
   * @param {string} infile file to import
   * @param {string} outfile output filename
   * @param {string} layer map layer to be imported - only for mult-layer infiles
   */
  addVector(mapset, infile, outfile, layer) {
    if (layer !== undefined) {
      grass(mapset, `v.import input="${infile}" layer="${layer}" output="${outfile}" --overwrite`)
    } else {
      grass(mapset, `v.import input="${infile}" output="${outfile}" --overwrite`)
    }
  },

  /**
   * Get all layers contained in map file
   * @param {string} mapset
   * @param {string} mapFile map file name
   */
  getLayers(mapset, mapFile) {
    const raw = grass(mapset, `v.import -l input=${mapFile}`)
    const index = raw.lastIndexOf(':')
    return raw.substring(index + 1).split('\n').filter(row => row.length)
  },

  checkWritableDir(path) {
    try {
      fs.accessSync(path, fs.constants.W_OK)
    } catch (err) {
      throw new Error(`Cannot launch module: ${path} is not writable.`)
    }
  },

  /**
   * Clip a map layer using the bounds of another layer
   * @param {string} mapset
   * @param {string} layer the layer to clip
   * @param {string} clipLayer the layer whose bounds are used for clipping
   * @param {string} outfile output filename
   */
  clip(mapset, layer, clipLayer, outfile) {
    grass(mapset, `v.clip input=${layer} clip=${clipLayer} output=${outfile} --overwrite`)
  },

  /**
   * Get the center coordinates of the current selection.
   * @param {string} mapset
   * @returns {[number, number]} center coordinates (east, north)
   */
  getCoordinates(mapset) {
    let EAST, NORTH
    let list = grass(mapset, `g.list type=vector`).trim()
    let region

    if (list.split('\n').indexOf('selection') > -1) {
      region = grass(mapset, `g.region -cg vector=selection`).trim()
    } else {
      region = grass(mapset, `g.region -cg vector=polygons_osm`).trim()
    }

    EAST = region.split('\n')[0].split('=')[1]
    NORTH = region.split('\n')[1].split('=')[1]

    return [EAST, NORTH]
  },

  getNumericColumns(mapset, layer) {
    try {
      return grass(mapset, `db.describe -c table=${layer}`).trim().split('\n').filter(col => col.match(/DOUBLE PRECISION|INTEGER/) && !col.match(/cat/i))
    } catch (err) {
      return []
    }
  },

  /**
   * returns all columns and their type of a table
   * @param {string} mapset 
   * @param {string} layer 
   * @return {object} [{'column':'','type':''},{},{},...]
   */
  getAllColumns(mapset, layer) {
    try {
      return grass(mapset, `db.describe -c table=${layer}`)
        .trim()
        .split('\n')
        .filter(col => col.match(/Column/) && !col.match(/cat/i))
        .map(line => { return { 'column': line.split(':')[1].trim(), 'type': line.split(':')[2].trim() } })
    } catch (err) {
      return []
    }
  },

  /**
   * Returns univariate statistics on selected table column for a GRASS vector map.
   * @param {string} mapset
   * @param {string} map
   * @param {string} column
   */
  getUnivar(mapset, map, column) {
    try {
      const rawArray = grass(mapset, `v.db.univar -e -g map=${map} column=${column}`).trim().split('\n')
      return rawArray.reduce((dict, line) => {
        const a = line.split('=')
        dict[a[0]] = a[1]
        return dict
      }, {})
    } catch (e) {
      throw new Error(e)
    }
  },

  /**
   * Returns min and max value of a univariate stat on selected table column for a GRASS vector map.
   * @param {string} mapset
   * @param {string} map
   * @param {string} column
   */
  getUnivarBounds(mapset, map, column) {
    const stats = module.exports.getUnivar(mapset, map, column)
    return stats !== undefined ? [round(stats.min, 2), round(stats.max, 2)] : []
  },

  /**
   * select all entries in a table
   * @param {string} mapset 
   * @param {string} table
   * @returns array of all entires
   */
  dbSelectAll(mapset, table) {
    const raw = grass(mapset, `db.select -v sql="select * from ${table}" vertical_separator=space`)
    return raw.split(' \n')
      .map(item => {
        return item
          .split('\n')
          .filter(row => row.length)
          .reduce((obj, row) => {
            const [key, val] = row.split('|').map(i => i.trim())
            obj[key] = val
            return obj
          }, {})
      })
  },

  /**
   * Identify the topology of a vector map
   * @param {string} mapset
   * @param {string} layer layer name
   * @returns {string} topology type (possible values are: point, line, area, mixed, empty)
   */
  getTopology(mapset, layer) {
    const info = grass(mapset, `v.info -t map=${layer}`).trim().split('\n').reduce((dict, line) => {
      const a = line.split('=')
      dict[a[0]] = a[1]
      return dict
    }, {})

    const topology = info.points ? (info.lines || info.centroids ? 'mixed' : 'point') : info.lines ? (info.centroids ? 'mixed' : 'line') : info.centroids ? 'area' : 'empty'
    return topology
  },

  /**
   * Export a vector map as a GeoPackage file in the GeoServer data directory.
   * @param {string} mapset
   * @param {string} infile file to import
   * @param {string} outfile output filename
   */
  gpkgOut(mapset, infile, outfile) {
    grass(mapset, `v.out.ogr format=GPKG input="${infile}" output="${GEOSERVER}/${outfile}.gpkg" --overwrite`)
  },

  /**
   * Overwrite the region of the given mapset. If no such mapset exists, create it
   * @param {string} mapset
   */
  initMapset(mapset) {
    if (!fs.existsSync(`${GRASS}/global/${mapset}`)) {
      fs.mkdirSync(`${GRASS}/global/${mapset}`)
    }
    fs.copyFileSync(`${GRASS}/global/PERMANENT/WIND`, `${GRASS}/global/${mapset}/WIND`)

    for (const file of fs.readdirSync(`${GRASS}/skel`)) {
      fs.copyFileSync(`${GRASS}/skel/${file}`, `${GRASS}/global/${mapset}/${file}`)
    }
  },

  /**
   * List available vector maps
   * @param {string} mapset
   * @return {string[]} names of available maps
   */
  listVector(mapset) {
    return grass(mapset, `g.list -m type=vector`).trim().split('\n')
  },

  /**
   * List all user uploaded vector maps
   * @return {string[]} names of available maps
   */
  listUserVector() {
    return grass('PERMANENT', 'g.list type=vector mapset=*').trim().split('\n')
      .filter(map => !map.match(/^((lines|points|polygons|relations)(_osm)?|selection|location_bbox)(@.+)?$/))
  },

  /**
   * Check if a mapset exists
   * @param {string} mapset
   * @returns {boolean} true if mapset exists
   */
  mapsetExists(mapset) {
    let exists = true
    try {
      grass(mapset, `g.list type=vector`)
    } catch (err) {
      exists = false
    }
    return exists
  },

  /**
   * Merge multiple PDF files into one
   * @param {string} outfile
   * @param  {...string} infiles
   */
  mergePDFs(outfile, ...infiles) {
    infiles = infiles.map(file => `"${file}"`).join(" ")
    execSync(`gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile="${outfile}" ${infiles}`)
  },

  /**
   * Remove a map layer
   * @param {string} mapset
   * @param {string} layer layer name
   */
  remove(mapset, layer) {
    grass(mapset, `g.remove -f type=vector name=${layer}`)
  },

  /**
   * Convert PS to PDF
   * @param {string} infile
   * @param {string} outfile
   */
  psToPDF(infile, outfile) {
    execSync(`ps2pdf ${infile} ${outfile}`)
  },

  /**
   * Convert text to PS
   * @param {string} infile
   * @param {string} outfile
   */
  textToPS(infile, outfile) {
    execSync(`enscript -p ${outfile} ${infile}`)
  },

  /**
   * Prints all attribute descriptions of a table
   * @param {string} table
   */
  getMetadata(mapset, table) {
    const columns = module.exports.getNumericColumns(mapset, table).map(col => col.split(':')[1].trim())
    const data = {
      tableObj: { headFields: ['table', 'description'], rows: [{ table: table, description: '' }] },
      columnObj: {
        headFields: ['column', 'description', 'min', 'max'],
        rows: columns.map(c => { return { column: c, description: '', min: undefined, max: undefined } })
      }
    }
    setBounds(data, mapset, table)
    addDescription(data, table)
    return JSON.stringify(data)
  },


  /**
   * Prints all the result files in the 'output' folder
   * @returns {array} list of result filenames
   */
  getResults() {
    const list = []
    fs.readdirSync(outputDir).forEach(file => {
      list.push(file)
    })
    return list
  },

  /**
   * get all files of a file type in a directory 
   * @param {string} directory directory to search in
   * @param {string} extension file extension
   * @returns {array} array of filenames
   */
  getFilesOfType(extension, directory) {
    function helper(dir, ext, files) {
      fs.readdirSync(dir).forEach(function (file) {
        if (fs.statSync(dir + "/" + file).isDirectory()) {
          files = helper(dir + "/" + file, ext, files)
        } else if (file.slice(file.lastIndexOf('.') + 1) === ext) {
          files.push(path.join(dir, "/", file))
        }
      })
      return files
    }
    return helper(directory, extension, [])
  },

  grass
}

/**
 * Run any GRASS command on a given mapset
 * @param {string} mapset
 * @param {string} args arguments to the command line
 */
function grass(mapset, args) {
  return execSync(`grass "${GRASS}/global/${mapset}" --exec ${args}`, { shell: '/bin/bash', encoding: 'utf-8' })
}

/**
 * add max and min attributes to each element of desc.columnObj.rows
 * @param {*} desc table description object
 * @param {*} mapset mapset name
 * @param {*} table table name
 */
function setBounds(desc, mapset, table) {
  let i = 0
  while (i < desc.columnObj.rows.length) {
    const bounds = module.exports.getUnivarBounds(mapset, table, desc.columnObj.rows[i].column)
    // add bounds when they exist, remove element when they don't
    if (bounds.length) {
      desc.columnObj.rows[i].min = bounds[0]
      desc.columnObj.rows[i].max = bounds[1]
      i++
    } else {
      desc.columnObj.rows.splice(i, 1)
    }
  }
}

/**
 * add description from metadata.json to 
 * @param {object} desc description object of a table
 * @param {string} table table name to search for
 */
function addDescription(desc, table) {
  let metadata = []
  try {
    metadata = require(`${GRASS}/metadata/metadata.json`)
  } catch (err) {
    throw new Error('metadata.json not found.')
  }
  if (metadata.length) {
    const meta = metadata.filter(m => m.table === table)[0]
    if (meta != undefined) {
      desc.columnObj.rows.forEach(row => {
        const data = meta.columns.filter(c => c.column === row.column)[0]
        if (data != undefined) row.description = data.description
      })
    }
  }
}

/**
 * round a string number to n digits after zero
 * @param {string} val 
 * @param {number} n 
 */
function round(val, n) {
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
