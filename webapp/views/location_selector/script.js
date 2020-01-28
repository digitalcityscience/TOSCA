const geoserverURL = 'http://127.0.0.1:8600/';

const dem = L.tileLayer.wms(geoserverURL + "geoserver/raster/wms", {
  layers: 'raster:dem',
  format: 'image/png',
  transparent: false,
  attribution: "<a href='https://www.hcu-hamburg.de/research/citysciencelab/?L=1' target=new>HCU CSL</a>",
  maxZoom: 20,
  minZoom: 1,
});

const waterLines = L.tileLayer.wms(geoserverURL + "geoserver/vector/wms", {
  layers: 'vector:water_lines_osm',
  format: 'image/png',
  transparent: true,
  attribution: "<a href='https://www.hcu-hamburg.de/research/citysciencelab/?L=1' target=new>HCU CSL</a>",
  maxZoom: 20,
  minZoom: 1,
});

const waterArea = L.tileLayer.wms(geoserverURL + "geoserver/vector/wms", {
  layers: 'vector:polygons',
  format: 'image/png',
  transparent: true,
  attribution: "<a href='https://www.hcu-hamburg.de/research/citysciencelab/?L=1' target=new>HCU CSL</a>",
  maxZoom: 20,
  minZoom: 1,
});

const roads = L.tileLayer.wms(geoserverURL + "geoserver/vector/wms", {
  layers: 'vector:lines_osm',
  format: 'image/png',
  transparent: true,
  attribution: "<a href='https://www.hcu-hamburg.de/research/citysciencelab/?L=1' target=new>HCU CSL</a>",
  maxZoom: 20,
  minZoom: 1,
});

const buildings = L.tileLayer.wms(geoserverURL + "geoserver/vector/wms", {
  layers: 'vector:polygons_osm',
  format: 'image/png',
  transparent: true,
  attribution: "<a href='https://www.hcu-hamburg.de/research/citysciencelab/?L=1' target=new>HCU CSL</a>",
  maxZoom: 20,
  minZoom: 1,
});

const selection = L.tileLayer.wms(geoserverURL + "geoserver/vector/wms", {
  layers: 'vector:selection',
  format: 'image/png',
  transparent: true,
  attribution: "<a href='https://www.hcu-hamburg.de/research/citysciencelab/?L=1' target=new>HCU CSL</a>",
  maxZoom: 20,
  minZoom: 1,
});

/* Marker line, keep this in line 128 */
var map = new L.Map('map', { center: new L.LatLng(20.291320, 85.817298), zoom: 9 }), drawnItems = L.featureGroup().addTo(map);
/* Marker line, keep this in line 130 */

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
}).addTo(map);

L.control.layers({
},
  {
    "Dem": dem,
    "Water lines": waterLines,
    "Water areas": waterArea,
    "Roads": roads,
    "Buildings": buildings,
    "Current selection": selection,
    "Drawing": drawnItems
  },
  { position: 'topright', collapsed: false }).addTo(map);

map.addControl(new L.Control.Draw
  ({
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

document.getElementById('saving').onclick = function (saving_draw) {
  /*  making a GeoJson from featureGroup */
  var data = featureGroup.toGeoJSON();

  /* Convert data to GeoJson string*/
  var convertedData = 'text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(data));
  /* saving */
  document.getElementById('saving').setAttribute('href', 'data:' + convertedData);
  document.getElementById('saving').setAttribute('download', '../../../data_from_browser/selection_1.geojson');
}

/*------------------------------------------------*/
map.on(L.Draw.Event.CREATED, function (event) {
  var layer = event.layer;
  drawnItems.addLayer(layer);
});

/* scale bar */
L.control.scale({ maxWidth: 300 }).addTo(map);

/* north arrow */
var north = L.control({ position: "bottomright" });
north.onAdd = function (map) {

  var div = L.DomUtil.create("div", "info legend");
  div.innerHTML = '<img src="images/north.png" />';
  return div;
}; north.addTo(map);
