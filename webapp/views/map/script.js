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

// Local layers (Bhubaneswar)

const bbswrMetropolitanArea = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_metropolitan_area',
  name: 'Metropolitan area',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const bbswrCityZone = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_municipality',
  name: 'BMC administrative units',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumAreas = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_slums',
  name: 'Informal settlements',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const landOwnership = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_land_ownership',
  name: 'Informal settlements: ownership',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumTotalPopulation = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_slum_houses_total_population',
  name: 'Households by total population',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const femalePopulation = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_slum_houses_female_population',
  name: 'Households by female population',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const malePopulation = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_slum_houses_male_population',
  name: 'Households by male population',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumOwnership = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_slum_houses_ownership',
  name: 'Households by type of ownership',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumReligions = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_slum_houses_religion',
  name: 'Households by religion',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const monthlyIncomes = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_slum_houses_monthly_income',
  name: 'Households by average monthly income',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const animals = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_slum_houses_livestock',
  name: 'Households by livestock',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumsBathrooms = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_slum_houses_bathrooms',
  name: 'Households by availability of sanitation',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const slumToilets = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_slum_houses_toilets',
  name: 'Households by availability of latrines',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const emptyPlaces = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_empty_places',
  name: 'Open spaces/vacant land',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 1,
});

const emptyPlacesOwnership = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'bbswr_empty_places_ownership',
  name: 'Open spaces/vacant land: ownership',
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
  "Bhubaneswar thematic maps": {
    [bbswrMetropolitanArea.options.name]: bbswrMetropolitanArea,
    [bbswrCityZone.options.name]: bbswrCityZone,
    [slumAreas.options.name]: slumAreas,
    [landOwnership.options.name]: landOwnership,
    [slumTotalPopulation.options.name]: slumTotalPopulation,
    [femalePopulation.options.name]: femalePopulation,
    [malePopulation.options.name]: malePopulation,
    [slumOwnership.options.name]: slumOwnership,
    [slumReligions.options.name]: slumReligions,
    [monthlyIncomes.options.name]: monthlyIncomes,
    [animals.options.name]: animals,
    [slumsBathrooms.options.name]: slumsBathrooms,
    [slumToilets.options.name]: slumToilets,
    [emptyPlaces.options.name]: emptyPlaces,
    [emptyPlacesOwnership.options.name]: emptyPlacesOwnership,
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
