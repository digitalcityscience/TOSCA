/* global L, lat, lon, geoserverUrl */

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
  legend: true,
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
  minZoom: 3
});

const timeMap = L.tileLayer.wms(rasterWMS, {
  layers: 'time_map_result',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

// Latacunga thematic maps
const latacungaDEM = L.tileLayer.wms(rasterWMS, {
  layers: 'ltca_dem',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const administrativeUnits = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_admin',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const floodRiskMap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_flood_risk',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const greenhouses = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_greenhouses',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const farms = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_farms',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const schools = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_schools',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const doctors = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_doct_offices',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const hospitals = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_hospitals',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const ltgaVulnerabilityMap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_vulnerabilidad',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const ltgaPopdenMap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_densidad_poblacion',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const ltgaAxisMap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_eje_vial',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const ltgaRoadMap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_vias_2004',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const ltgaCropMap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_cultivo_principal',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const ltgaAshMap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_isopacas',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const ltgaEruptMap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_amenaza_coto',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const productiveInfrastructure = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_productive_infrastructure',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const producerAssociations = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_producer_associations',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const marketsSquares = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_markets_squares',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const safePoints = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_safe_points',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const evacuationRoutes = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_evacuation_routes',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const sirens = L.tileLayer.wms(vectorWMS, {
  layers: 'ltca_sirens',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

// Drawings
const drawnItems = L.featureGroup().addTo(map);

// Control for map legends. For those item, where the linked map has a "legend: true," property, a second checkbox will displayed.
L.control.legend({ position: 'bottomleft' }).addTo(map);

// Overlay layers are grouped
const groupedOverlays = {
  "Background map": {
    "OpenStreetMap": osm
  },
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
  "Latacunga: thematic maps": {
    "Elevation map": latacungaDEM,
    "Administrative units": administrativeUnits,
    "Population density": ltgaPopdenMap,
    "Greenhouses": greenhouses,
    "Farms and orchards": farms,
    "Schools": schools,
    "Doctors and dentists": doctors,
    "Hospitals and clinics": hospitals,
    "AxisMap": ltgaAxisMap,
    "RoadMap": ltgaRoadMap,
    "CropMap": ltgaCropMap,
    "Productive Infrastructure":productiveInfrastructure,
    "Producer associations":producerAssociations,
    "Markets and squares":marketsSquares,
    "Safe points":safePoints,
    "Evacuation routes":evacuationRoutes,
    "Early warning sirens":sirens
  },
  "Latacunga: volcanic threats": {
    "Affected areas": ltgaEruptMap,
    "Lahar risk": floodRiskMap,
    "Ash fall risk": ltgaAshMap,
    "Vulnerability": ltgaVulnerabilityMap,
  },
}

// Use the custom grouped layer control, not "L.control.layers"
L.control.groupedLayers({}, groupedOverlays, { position: 'topright', collapsed: false }).addTo(map);

// L.control.groupedLayers({}, customLayers, { position: 'topright', collapsed: false }).addTo(map);

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
