const attributionCSL = '<a href="https://www.hcu-hamburg.de/research/citysciencelab/?L=1" target=new>HCU CSL</a>';
const attributionOSM = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';

const dem = L.tileLayer.wms(geoserverURL + 'geoserver/raster/wms', {
  layers: 'raster:dem',
  format: 'image/png',
  transparent: false,
  attribution: attributionCSL,
  maxZoom: 20,
  minZoom: 1,
});

const waterLines = L.tileLayer.wms(geoserverURL + 'geoserver/vector/wms', {
  layers: 'vector:water_lines_osm',
  format: 'image/png',
  transparent: true,
  attribution: attributionCSL,
  maxZoom: 20,
  minZoom: 1,
});

const waterArea = L.tileLayer.wms(geoserverURL + 'geoserver/vector/wms', {
  layers: 'vector:polygons',
  format: 'image/png',
  transparent: true,
  attribution: attributionCSL,
  maxZoom: 20,
  minZoom: 1,
});

const roads = L.tileLayer.wms(geoserverURL + 'geoserver/vector/wms', {
  layers: 'vector:lines_osm',
  format: 'image/png',
  transparent: true,
  attribution: attributionCSL,
  maxZoom: 20,
  minZoom: 1,
});

const buildings = L.tileLayer.wms(geoserverURL + 'geoserver/vector/wms', {
  layers: 'vector:polygons_osm',
  format: 'image/png',
  transparent: true,
  attribution: attributionCSL,
  maxZoom: 20,
  minZoom: 1,
});

const selection = L.tileLayer.wms(geoserverURL + 'geoserver/vector/wms', {
  layers: 'vector:selection',
  format: 'image/png',
  transparent: true,
  attribution: attributionCSL,
  maxZoom: 20,
  minZoom: 1,
});

var map = new L.Map('map', {
  center: new L.LatLng(lat, lon), zoom: 9
})
var drawnItems = L.featureGroup().addTo(map);

// OSM basemap
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: attributionOSM
}).addTo(map);

L.control.layers(
  {},
  {
    'Dem': dem,
    'Water lines': waterLines,
    'Water areas': waterArea,
    'Roads': roads,
    'Buildings': buildings,
    'Current selection': selection,
    'Drawing': drawnItems
  },
  { position: 'topright', collapsed: false }).addTo(map);

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
    polygon: true,
    rectangle: false,
    circle: false,
    marker: false,
    circlemarker: false,
  }
}));

var featureGroup = L.featureGroup().addTo(map);
map.on('draw:created', (saving_draw) => {
  /* Creating a new item (polygon, line ... ) will be added to the feature group */
  featureGroup.addLayer(saving_draw.layer);
});

map.on(L.Draw.Event.CREATED, (event) => {
  var layer = event.layer;
  drawnItems.addLayer(layer);
});

/* scale bar */
L.control.scale({ maxWidth: 300 }).addTo(map);

/* north arrow */
var north = L.control({ position: 'bottomright' });
north.onAdd = () => document.getElementById('north-arrow');
north.addTo(map);

/*----- Save drawing -----------------------------------------*/

function save() {
  /* making a GeoJson from featureGroup */
  var geojson = featureGroup.toGeoJSON();

  sendMessage('/select_location', { data: geojson });
}
