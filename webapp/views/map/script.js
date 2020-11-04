/* global $, L, lat, lon, geoserverUrl */

const map = new L.Map('map', {
  center: new L.LatLng(lat, lon),
  zoom: 13,
  minZoom: 4,
  touchZoom: true
});

const rasterWMS = geoserverUrl + 'geoserver/raster/wms';
const vectorWMS = geoserverUrl + 'geoserver/vector/wms';

// Background map
const osm = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
}).addTo(map);

const hot = L.tileLayer('https://tile-{s}.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors; Humanitarian map style by <a href="https://www.hotosm.org/">HOT</a>'
});

// Basemap
const waterways = L.tileLayer.wms(vectorWMS, {
  layers: 'osm_waterways',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const roads = L.tileLayer.wms(vectorWMS, {
  layers: 'osm_roads',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const buildings = L.tileLayer.wms(vectorWMS, {
  layers: 'osm_buildings',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const basemapBbox = L.tileLayer.wms(vectorWMS, {
  layers: 'basemap_bbox',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

// Selection
const selection = L.tileLayer.wms(vectorWMS, {
  layers: 'selection',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

// Time map module
const fromPoints = L.tileLayer.wms(vectorWMS, {
  layers: 'time_map_from_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const viaPoints = L.tileLayer.wms(vectorWMS, {
  layers: 'time_map_via_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const strickenArea = L.tileLayer.wms(vectorWMS, {
  layers: 'time_map_stricken_area',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1,
});

const timeMap = L.tileLayer.wms(rasterWMS, {
  layers: 'time_map_result',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1
});

// Local layers (Bhubaneshwar)

const bbswrMetropolitanArea = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bubaneshwar_metropolitan_area',
  name: 'Bubaneshwar metropolitan area',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const bbswrCityZone = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bubaneshwar_city_zone',
  name: 'Bubaneshwar city zone',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumAreas = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slums',
  name: 'Slums of Bubaneshwar',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});
const slumTotalPopulation = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_total_population_households',
  name: 'Total population by households',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const femalePopulation = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_female_population_households',
  name: 'Female habitanst by households',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const malePopulation = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_male_population_households',
  name: 'Male habitanst by households',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});
const emptyPlaceTypes = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_empty_place_types',
  name: 'Open/Vacant empty places',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const emptyPlaceCategory = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_empty_places_category',
  name: 'Dry/Green empty places',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const landOwnership = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_land_ownership',
  name: 'Land ownership in Bubaneshwar',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumsEmptyOwnership = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:empty_places_ownership',
  name: 'Ownership of empty areas',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumOwnerhip = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: '	vector:bbswr_slum_ownership',
  name: 'Ownerhips of slum houses',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumReligions = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_religions',
  name: 'Religions by households',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const monthlyIncomes = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_average_incomes',
  name: 'Monthly average incomes per household',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const animals = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_animals',
  name: 'Household with/without livestocks',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumsBathrooms = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_bathrooms',
  name: 'Bathroom facilities in the slums',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumTapwater = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_tapwater',
  name: 'Water accessibility in slums',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumToilettes = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_toilettes',
  name: 'Toilette facilities in the slums',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

// Drawings
const drawnItems = L.featureGroup().addTo(map);

// Control for map legends
L.control.legend(
  { position: 'bottomleft' }
).addTo(map);

// Grouped layer control
const baseLayers = {
  "OSM Standard style": osm,
  "OSM Humanitarian style": hot
}
const groupedOverlays = {
  "Basemap": {
    "Waterways": waterways,
    "Roads": roads,
    "Buildings": buildings,
    "Basemap boundary": basemapBbox,
    "Current selection": selection
  },
  "Time map": {
    "Start point": fromPoints,
    "Via point": viaPoints,
    "Affected area": strickenArea,
    "Road-level time map": timeMap
  },
  "Bhubaneshwar thematic maps": {
    [bbswrMetropolitanArea.options.name]: bbswrMetropolitanArea,
    [bbswrCityZone.options.name]: bbswrCityZone,
    [slumAreas.options.name]: slumAreas,
    [slumTotalPopulation.options.name]: slumTotalPopulation,
    [femalePopulation.options.name]: femalePopulation,
    [malePopulation.options.name]: malePopulation,
    [emptyPlaceTypes.options.name]: emptyPlaceTypes,
    [emptyPlaceCategory.options.name]: emptyPlaceCategory,
    [landOwnership.options.name]: landOwnership,
    [slumsEmptyOwnership.options.name]: slumsEmptyOwnership,
    [slumOwnerhip.options.name]: slumOwnerhip,
    [slumReligions.options.name]: slumReligions,
    [monthlyIncomes.options.name]: monthlyIncomes,
    [animals.options.name]: animals,
    [slumsBathrooms.options.name]: slumsBathrooms,
    [slumTapwater.options.name]: slumTapwater,
    [slumToilettes.options.name]: slumToilettes,
  }
}

// Use the custom grouped layer control, not "L.control.layers"
L.control.groupedLayers(baseLayers, groupedOverlays, { position: 'topright', collapsed: false }).addTo(map);

// Prevent click/scroll events from propagating to the map through the layer control
const layerControlElement = $('.leaflet-control-layers')[0];
L.DomEvent.disableClickPropagation(layerControlElement);
L.DomEvent.disableScrollPropagation(layerControlElement);

map.addControl(new L.Control.Draw({
  edit: {
    featureGroup: drawnItems,
    poly: {
      allowIntersection: false
    }
  },
  draw: {
    polygon: {
      showArea: true,
      fill: '#FFFFFF',
    },
    polyline: false,
    rectangle: false,
    circle: false,
    marker: false,
    circlemarker: true
  }
}));

// Save drawed items in feature group
map.on(L.Draw.Event.CREATED, (event) => {
  drawnItems.addLayer(event.layer);
});

/* scale bar */
L.control.scale({ maxWidth: 300, position: 'bottomright' }).addTo(map);
