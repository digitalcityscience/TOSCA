const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html

const GRASS = process.env.GRASS_DIR
const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`

module.exports = {
  // This is to import an OSM map file.
  // Parameters: {filename to import, layer name, output filename for GRASS}
  addOsm(mapset, ...args) {
    execSync(`grass "${GRASS}/global/${mapset}" --exec v.in.ogr -o input="${args[0]}" layer="${args[1]}" output="${args[2]}" --overwrite --quiet`)
  },

  // This is to import geotiff raster maps.
  addRaster(mapset, ...args) {
    execSync(`grass "${GRASS}/global/${mapset}" --exec r.import input="${args[0]}" output="${args[1]}" --overwrite`)
  },

  // This is to import a vector map file.
  // Parameters: {filename to import, output filename for GRASS}
  addVector(mapset, ...args) {
    execSync(`grass "${GRASS}/global/${mapset}" --exec v.import input="${args[0]}" output="${args[1]}" --overwrite`)
  },

  // Get the center coordinates of the current selection
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

  // This function export a file in the geoserver data dir. Output fileformat can only GPKG.
  // Parameters: {GRASS vector to export, filename after export in geoserver dir}
  gpkgOut(mapset, ...args) {
    execSync(`grass "${GRASS}/global/${mapset}" --exec v.out.ogr format=GPKG input="${args[0]}" output="${GEOSERVER}/${args[1]}.gpkg" --overwrite --quiet`)
  },

  // Check if a mapset exists
  mapsetExists(mapset) {
    let exists = true
    try {
      execSync(`grass "${GRASS}/global/${mapset}" --exec g.list type=vector`)
    } catch (err) {
      exists = false
    }
    return exists
  }
}
