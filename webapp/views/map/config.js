// eslint-disable-next-line no-unused-vars
const services = [
  {
    layers: 'osm_waterways',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Waterways',
    type: 'vector',
    group: 'Basemap'
  }, 
  {
    layers: 'osm_roads',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Roads',
    type: 'vector',
    group: 'Basemap'
  }, 
  {
    layers: 'osm_buildings',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Buildings',
    type: 'vector',
    group: 'Basemap'
  }, 
  {
    layers: 'basemap_bbox',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Basemap boundary',
    type: 'vector',
    group: 'Basemap'
  }, 
  {
    layers: 'selection',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Current selection',
    type: 'vector',
    group: 'Selection'
  }, 
  {
    layers: 'time_map_from_points',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 3,
    displayName: 'Start point',
    type: 'vector',
    group: 'Time map module'
  }, 
  {
    layers: 'time_map_via_points',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 3,
    displayName: 'Via point',
    type: 'vector',
    group: 'Time map module'
  }, 
  {
    layers: 'time_map_stricken_area',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 3,
    displayName: 'Affected area',
    type: 'vector',
    group: 'Time map module'
  }, 
  {
    layers: 'time_map_result',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Road-level time map',
    type: 'raster',
    group: 'Time map module'
  }
]