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

/*----- Save drawing -----------------------------------------*/

var featureGroup = L.featureGroup().addTo(map);
map.on('draw:created', function (saving_draw) {
  /* Creating a new item (polygon, line ... ) will added to the feature group */
  featureGroup.addLayer(saving_draw.layer);
});

function save() {
  /* making a GeoJson from featureGroup */
  var data = featureGroup.toGeoJSON();

  /* Convert data to GeoJson string*/
  var convertedData = 'text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(data));
  /* saving */
  document.getElementById('save').setAttribute('href', 'data:' + convertedData);
  document.getElementById('save').setAttribute('download', '../../../data_from_browser/selection_1.geojson');
}

/*------------------------------------------------*/

/*-- Save file (exit) ----------------------------*/

var saveFile = () => {
  // Get the data from each element on the form.
  const item_1 = document.getElementById('exit');
  var data = '' + item_1.value + '\n';
  const textToBLOB = new Blob([data], { type: 'text/plain' });
  const sFileName = 'exit';
  var newLink = document.createElement('a');
  newLink.download = sFileName;
  if (window.webkitURL != null) {
    newLink.href = window.webkitURL.createObjectURL(textToBLOB);
  }
  else {
    newLink.href = window.URL.createObjectURL(textToBLOB);
    newLink.style.display = 'none';
    document.body.appendChild(newLink);
  }
  newLink.click();
}

/*------------------------------------------------*/

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
