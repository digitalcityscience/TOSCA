const map = new L.Map('map', {
  center: new L.LatLng(lat, lon),
  zoom: 13,
  minZoom: 4,
  touchZoom: true
});

// Base layers
const osm = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
}).addTo(map);

const waterLines = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:water_lines_osm',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const roads = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:lines_osm',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const buildings = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:polygons_osm',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const selection = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:selection',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const drawnItems = L.featureGroup().addTo(map);

// extension layers
const queryArea1 = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:query_area_1',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const strickenArea = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1_stricken_area',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const timeMap = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1_time_map',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const fromPoints = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1_from_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const viaPoints = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1_via_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const toPoints = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1_to_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const accessibilityMap = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1b_accessibility_map',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 3
});

const accessibilityPoints = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1b_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const queryMap = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:query_map',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const queryResult = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:query_result',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

//Control for map legends. For those item, where the linked map has a "legend_yes: true," property, a second checkbox will displayed.
L.control.legend(
  { position: 'bottomleft' }
).addTo(map);

// Overlay layers are grouped
const groupedOverlays = {
  "Basemaps": {
    'OpenStreetMap': osm
  },
  "Location": {
    'Water lines': waterLines,
    'Roads': roads,
    'Buildings': buildings,
  },
  "User inputs": {
    'Current selection': selection,
    'Drawings on the map': drawnItems,
    'Query area': queryArea1,
    'Query map': queryMap,
    "From-points": fromPoints,
    "Via-points": viaPoints,
    "To-points": toPoints,
    "Stricken area": strickenArea
  },
  "Results": {
    "Road-level time map": timeMap,
    'Query result': queryResult,
    "Accessibility map": accessibilityMap,
    "Accessing points": accessibilityPoints
  }
};

// Use the custom grouped layer control, not "L.control.layers"
L.control.groupedLayers({}, groupedOverlays, { position: 'topright', collapsed: false }).addTo(map);

map.addControl(new L.Control.Draw({
  edit: {
    featureGroup: drawnItems,
    poly: { allowIntersection: false }
  },
  draw: {
    polygon: {
      allowIntersection: false,
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
