const { execSync } = require('child_process') // Documentation: https://nodejs.org/api/child_process.html

const GEOSERVER = `${process.env.GEOSERVER_DATA_DIR}/data`

module.exports = {
  // This is to import an Open street map vector map file. Parameters: {filename to import,layer name, output filename for the GRASS}
  Add_Osm(mapset, ...args) {
    execSync(`grass -f "${mapset}" --exec v.in.ogr -o input="${args[0]}" layer="${args[1]}" output="${args[2]}" --overwrite --quiet`)
  },

  // This function export a file in the geoserver data dir. Output fileformat can only GPKG. Parameters: {GRASS vector to export,filename after export in geoserver dir}
  Gpkg_Out(mapset, ...args) {
    execSync(`grass -f "${mapset}" --exec v.out.ogr format=GPKG input="${args[0]}" output="${GEOSERVER}/${args[1]}.gpkg" --overwrite --quiet`)
  }
}
