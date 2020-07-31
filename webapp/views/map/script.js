/* eslint-disable no-undef */

const map = new L.Map('map', {
  center: new L.LatLng(lat, lon),
  zoom: 13,
  minZoom: 4,
  touchZoom: true
})

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

//Extension layers
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

const Stricken_Area = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1_stricken_area',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const TimeMap = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1_time_map',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 1
});

const FromPoints = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1_from_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const ViaPoints = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1_via_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});

const ToPoints = L.tileLayer.wms(geoserverUrl + "geoserver/vector/wms/", {
  layers: 'vector:m1_to_points',
  format: 'image/png',
  transparent: true,
  maxZoom: 20,
  minZoom: 3
});


// Local layers (Bhubaneshwar)
// Watch out the property 'legend_yes'. It must be  true if you want to allow a second checckbox to display (refer to views/launch/legend.js and views/index.pug)   

const Bbswr_Metropolitan_Area = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bubaneshwar_metropolitan_area',
  name: 'Bubaneshwar metropolitan area',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Bbswr_City_Zone = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bubaneshwar_city_zone',
  name: 'Bubaneshwar city zone',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Slum_Areas = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slums',
  name: 'Slums of Bubaneshwar',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});
const Slum_Total_Population = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_total_population_households',
  name: 'Total population by households',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Female_Population = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_female_population_households',
  name: 'Female habitanst by households',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Male_Population = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_male_population_households',
  name: 'Male habitanst by households',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});
const Empty_Place_Types = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_empty_place_types',
  name: 'Open/Vacant empty places',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Empty_Place_Category = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_empty_places_category',
  name: 'Dry/Green empty places',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Land_Ownership = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_land_ownership',
  name: 'Land ownership in Bubaneshwar',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Slums_Empty_Ownership = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:empty_places_ownership',
  name: 'Ownership of empty areas',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Slum_Ownerhip = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: '	vector:bbswr_slum_ownership',
  name: 'Ownerhips of slum houses',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Slum_Religions = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_religions',
  name: 'Religions by households',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Monthly_Incomes = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_average_incomes',
  name: 'Monthly average incomes per household',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Animals = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_animals',
  name: 'Household with/without livestocks',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Slums_Bathrooms = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_bathrooms',
  name: 'Bathroom facilities in the slums',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Slum_Tapwater = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_tapwater',
  name: 'Water accessibility in slums',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

const Slum_Toilettes = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
  layers: 'vector:bbswr_slum_toilettes',
  name: 'Toilette facilities in the slums',
  format: 'image/png',
  transparent: true,
  legend_yes: true,
  maxZoom: 20,
  minZoom: 1,
});

// Control for map legends. For those item, where the linked map has a "legend_yes: true," property, a second checkbox will displayed.
L.control.legend(
  { position: 'bottomleft' }
).addTo(map);

const baseLayers = {
  'OpenStreetMap': osm
};

// Overlay layers are grouped
const groupedOverlays = {
  "Location": {
    'Water lines': waterLines,
    'Roads': roads,
    'Buildings': buildings,
    'Current selection': selection,
    'Drawings on the map': drawnItems
  },
  "Results": {
    'Query area 1': query_area_1,
    'Query results 1': query_result_area_1,
    'Query results 3': query_result_point_1,
    "Stricken area": Stricken_Area,
    "Road-level time map": TimeMap,
    "From-points": FromPoints,
    "Via-points": ViaPoints,
    "To-points": ToPoints
  }

};


// Use the custom grouped layer control, not "L.control.layers"
L.control.groupedLayers(baseLayers, groupedOverlays, { position: 'topright', collapsed: false }).addTo(map);

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

/* north arrow */
const north = L.control({ position: 'bottomright' });
north.onAdd = () => document.getElementById('north-arrow');
north.addTo(map);
