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

// Drawings
const drawnItems = L.featureGroup().addTo(map);

// Control for map legends. For those item, where the linked map has a "legendYes: true," property, a second checkbox will displayed.
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
    [services.waterways.displayName]: createWms(services.waterways),
    [services.roads.displayName]: createWms(services.roads),
    [services.buildings.displayName]: createWms(services.buildings),
    [services.basemapBbox.displayName]: createWms(services.basemapBbox),
    [services.selection.displayName]: createWms(services.selection)
  },
  "Time map": {
    [services.fromPoints.displayName]: createWms(services.fromPoints),
    [services.viaPoints.displayName]: createWms(services.viaPoints),
    [services.strickenArea.displayName]: createWms(services.strickenArea),
    [services.timeMap.displayName]: createWms(services.timeMap)
  }
};

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

// eslint-disable-next-line no-unused-vars
function refreshLayer(layer) {
  // Force reloading of the layer
  layer.setParams({ ts: Date.now() });
}

/**
 * create wms service based on serviceConf
 * @param {object} service config object from config.js
 */
function createWms(service) {
  return service.type === 'vector' ? L.tileLayer.wms(vectorWMS, service) : L.tileLayer.wms(rasterWMS, service)
}