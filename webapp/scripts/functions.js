const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`
const GRASS = process.env.GRASS_DIR

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
   * Remove a map layer
   * @param {string} mapset
   * @param {string} layer layer name
   */
  remove(mapset, layer) {
    grass(mapset, `g.remove -f type=vector name=${layer}`)
  },

  grass
}

/**
 * Run any GRASS command on a given mapset
 * @param {string} mapset
 * @param {string} args arguments to the command line
 */
function grass(mapset, args) {
  return execSync(`grass "${GRASS}/global/${mapset}" --exec ${args}`, { encoding: 'utf-8' })
}
