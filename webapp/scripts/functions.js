const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html

const GRASS = process.env.GRASS_DIR
const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`

module.exports = {
  /**
   * Import an OSM map file into a GRASS mapset.
   * @param {string} mapset
   * @param {string} infile file to import
   * @param {string} layer layer name
   * @param {string} outfile output filename
   */
  addOsm(mapset, infile, layer, outfile) {
    execSync(`grass "${GRASS}/global/${mapset}" --exec v.in.ogr -o input="${infile}" layer="${layer}" output="${outfile}" --overwrite --quiet`)
  },

  /**
   * Import a raster map file into a GRASS mapset.
   * @param {string} mapset
   * @param {string} infile file to import
   * @param {string} outfile output filename
   */
  addRaster(mapset, infile, outfile) {
    execSync(`grass "${GRASS}/global/${mapset}" --exec r.import input="${infile}" output="${outfile}" --overwrite`)
  },

  /**
   * Import a vector map file into a GRASS mapset.
   * @param {string} mapset
   * @param {string} infile file to import
   * @param {string} outfile output filename
   */
  addVector(mapset, infile, outfile) {
    execSync(`grass "${GRASS}/global/${mapset}" --exec v.import input="${infile}" output="${outfile}" --overwrite`)
  },

  /**
   * Clip a map layer using the bounds of another layer
   * @param {string} mapset
   * @param {string} layer the layer to clip
   * @param {string} clipLayer the layer whose bounds are used for clipping
   * @param {string} outfile output filename
   */
  clip(mapset, layer, clipLayer, outfile) {
    execSync(`grass "${GRASS}"/global/${mapset} --exec v.clip input=${layer} clip=${clipLayer} output=${outfile} --overwrite`)
  },

  /**
   * Get the center coordinates of the current selection.
   * @param {string} mapset
   * @returns {[number, number]} center coordinates (east, north)
   */
  getCoordinates(mapset) {
    let EAST, NORTH
    let list = execSync(`grass "${GRASS}/global/${mapset}" --exec g.list type=vector`, { encoding: 'utf-8' })
    let region

    if (list.split('\n').indexOf('selection') > -1) {
      region = execSync(`grass "${GRASS}/global/${mapset}" --exec g.region -cg vector=selection`, { encoding: 'utf-8' })
    } else {
      region = execSync(`grass "${GRASS}/global/${mapset}" --exec g.region -cg vector=polygons_osm`, { encoding: 'utf-8' })
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
    execSync(`grass "${GRASS}/global/${mapset}" --exec v.out.ogr format=GPKG input="${infile}" output="${GEOSERVER}/${outfile}.gpkg" --overwrite --quiet`)
  },

  /**
   * Check if a mapset exists
   * @param {string} mapset
   * @returns {boolean} true if mapset exists
   */
  mapsetExists(mapset) {
    let exists = true
    try {
      execSync(`grass "${GRASS}/global/${mapset}" --exec g.list type=vector`)
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
    execSync(`grass "${GRASS}/global/${mapset}" --exec g.remove -f type=vector name=${layer}`)
  }
}
