/* eslint-disable no-undef */

const map = new L.Map('map', {
  center: new L.LatLng(lat, lon),
  zoom: 11,
  minZoom: 4
})

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

const query_area_1 = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:query_area_1',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const query_result_area_1 = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:query_result_area_1',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const query_result_point_1 = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:query_result_point_1',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const Stricken_Area = L.tileLayer.wms("http://127.1.1.1:8080/geoserver/vector/wms/", {
  layers: 'vector:m1_stricken_area',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const TimeMap = L.tileLayer.wms("http://127.1.1.1:8080/geoserver/raster/wms/", {
  layers: 'raster:m1_time_map',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const TimeMapInterpolated = L.tileLayer.wms("http://127.1.1.1:8080/geoserver/raster/wms/", {
  layers: 'raster:m1_time_map_interpolated',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const FromPoints = L.tileLayer.wms("http://127.1.1.1:8080/geoserver/vector/wms/", {
  layers: 'vector:m1_from_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const ViaPoints = L.tileLayer.wms("http://127.1.1.1:8080/geoserver/vector/wms/", {
  layers: 'vector:m1_via_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const ToPoints = L.tileLayer.wms("http://127.1.1.1:8080/geoserver/vector/wms/", {
  layers: 'vector:m1_to_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const drawnItems = L.featureGroup().addTo(map);

L.control.layers(
  {},
  {
    'OpenStreetMap': osm,
    'Water lines': waterLines,
    'Roads': roads,
    'Buildings': buildings,
    'Current selection': selection,
    'Query area 1': query_area_1,
    'Query results 1': query_result_area_1,
    'Query results 3': query_result_point_1,
    "Stricken area": Stricken_Area,
    "Road-level time map": TimeMap,
    "Interpolated time map": TimeMapInterpolated,
    "From-points": FromPoints,
    "Via-points": ViaPoints,
    "To-points": ToPoints,
    'Drawing': drawnItems
  },
  { position: 'topright', collapsed: false }
).addTo(map);

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

const featureGroup = L.featureGroup().addTo(map);

map.on('draw:created', (saving_draw) => {
  /* Creating a new item (polygon, line ... ) will be added to the feature group */
  featureGroup.addLayer(saving_draw.layer);
});

map.on(L.Draw.Event.CREATED, (event) => {
  drawnItems.addLayer(event.layer);
});

/* scale bar */
L.control.scale({ maxWidth: 300 }).addTo(map);

/* north arrow */
const north = L.control({ position: 'bottomright' });
north.onAdd = () => document.getElementById('north-arrow');
north.addTo(map);
