// eslint-disable-next-line no-unused-vars
const layers = [
  {
    layers: 'osm_waterways',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Waterways',
    type: 'vector',
    group: 'Basemap',
    getFeatureInfo: true
  },
  {
    layers: 'osm_roads',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Roads',
    type: 'vector',
    group: 'Basemap',
    getFeatureInfo: true
  },
  {
    layers: 'osm_buildings',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Buildings',
    type: 'vector',
    group: 'Basemap',
    getFeatureInfo: true
  },
  {
    layers: 'basemap_bbox',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Basemap boundary',
    type: 'vector',
    group: 'Basemap',
    getFeatureInfo: false
  },
  {
    layers: 'selection',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Current selection',
    type: 'vector',
    group: 'Basemap',
    getFeatureInfo: false
  },
  {
    layers: 'time_map_from_points',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 3,
    displayName: 'Start point',
    type: 'vector',
    group: 'Time map',
    getFeatureInfo: false
  },
  {
    layers: 'time_map_stricken_area',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 3,
    displayName: 'Affected area',
    type: 'vector',
    group: 'Time map',
    getFeatureInfo: false
  },
  {
    layers: 'time_map_vector',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    displayName: 'Road-level time map',
    type: 'vector',
    group: 'Time map',
    getFeatureInfo: false
  }
]
