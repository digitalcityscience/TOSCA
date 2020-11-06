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
  legend: true,
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

const gradoAmenaza = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_grado_amenaza',
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

const ltgaPopdenRaster = L.tileLayer.wms(rasterWMS, {
  layers: 'ltga_interpolated_density',
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

const ltgaBuildings = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_buildingfloors',
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

const ltgaLulcMap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_uso_cobertura',
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

const ltgaLumap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_luminaria',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const ltgaTramomap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_traDistAereo',
  format: 'image/png',
  transparent: true,
  legend: true,
  maxZoom: 20,
  minZoom: 3
});

const ltgaTrSbmap = L.tileLayer.wms(vectorWMS, {
  layers: 'ltga_traDistSub',
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
  "Latacunga: thematic maps": {
    "Elevation map": latacungaDEM,
    "Administrative units": administrativeUnits,
    "Population density": ltgaPopdenMap,
    "Population density raster": ltgaPopdenRaster,
    "Greenhouses": greenhouses,
    "Farms and orchards": farms,
    "Schools": schools,
    "Doctors and dentists": doctors,
    "Hospitals and clinics": hospitals,
    "Building Floors": ltgaBuildings,
    "Vías Latacunga": ltgaAxisMap,
    "Vías Cotopaxi": ltgaRoadMap,
    'Luminaria': ltgaLumap,
    'TramoDistribuciónAereo': ltgaTramomap,
    'TramoDistriSubterraneo': ltgaTrSbmap,
    "Cultivo principal": ltgaCropMap,
    "Uso Cobertura": ltgaLulcMap,
    "Productive Infrastructure":productiveInfrastructure,
    "Producer associations":producerAssociations,
    "Markets and squares":marketsSquares,
    "Safe points":safePoints,
    "Evacuation routes":evacuationRoutes,
    "Early warning sirens":sirens
  },
  "Latacunga: volcanic threats": {
    "Amenanza Cotopaxi": ltgaEruptMap,
    "Grado amenanza lahares": gradoAmenaza,
    "Caída ceniza Cotopaxi": ltgaAshMap,
    "Vulnerabilidad": ltgaVulnerabilityMap,
  },
}

// Use the custom grouped layer control, not "L.control.layers"
L.control.groupedLayers(baseLayers, groupedOverlays, { position: 'topright', collapsed: false }).addTo(map);

// Prevent click/scroll events from propagating to the map through the layer control
const layerControlElement = $('.leaflet-control-layers')[0];
L.DomEvent.disableClickPropagation(layerControlElement);
L.DomEvent.disableScrollPropagation(layerControlElement);

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