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
    group: 'Basemap'
  },
  {
    layers: 'time_map_from_points',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 3,
    displayName: 'Start point',
    type: 'vector',
    group: 'Time map'
  },
  {
    layers: 'time_map_via_points',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 3,
    displayName: 'Via point',
    type: 'vector',
    group: 'Time map'
  },
  {
    layers: 'time_map_stricken_area',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 3,
    displayName: 'Affected area',
    type: 'vector',
    group: 'Time map'
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
    group: 'Time map'
  },
  {
    layers: 'bbswr_metropolitan_area',
    displayName: 'Metropolitan area',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_municipality',
    displayName: 'BMC administrative units',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_slums',
    displayName: 'Informal settlements',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_land_ownership',
    displayName: 'Informal settlements: ownership',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_slum_houses_total_population',
    displayName: 'Households by total population',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_slum_houses_female_population',
    displayName: 'Households by female population',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_slum_houses_male_population',
    displayName: 'Households by male population',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_slum_houses_ownership',
    displayName: 'Households by type of ownership',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_slum_houses_religion',
    displayName: 'Households by religion',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_slum_houses_monthly_income',
    displayName: 'Households by average monthly income',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_slum_houses_livestock',
    displayName: 'Households by livestock',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_slum_houses_bathrooms',
    displayName: 'Households by availability of sanitation',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_slum_houses_toilets',
    displayName: 'Households by availability of latrines',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_empty_places',
    displayName: 'Open spaces/vacant land',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  },
  {
    layers: 'bbswr_empty_places_ownership',
    displayName: 'Open spaces/vacant land: ownership',
    format: 'image/png',
    transparent: true,
    legend: true,
    maxZoom: 20,
    minZoom: 1,
    type: 'vector',
    group: 'Bhubaneswar thematic maps'
  }
]
