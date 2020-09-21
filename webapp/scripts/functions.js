const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html
const fs = require('fs')

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
   */
  addVector(mapset, infile, outfile) {
    grass(mapset, `v.import input="${infile}" output="${outfile}" --overwrite`)
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
    return grass(mapset, `db.describe -c table=${layer}`).trim().split('\n').filter(col => col.match(/DOUBLE PRECISION|INTEGER/)).filter(col => !col.match(/cat/i))
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
  describeTable(table) {
    return grass('PERMANENT', `db.describe table="${table}"`)
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
