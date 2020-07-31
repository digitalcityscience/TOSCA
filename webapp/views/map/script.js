/* eslint-disable no-undef */


//  This map script containes Bhubaneshwar local layers too. Therefore it is not for generick purposes.


const map = new L.Map('map', {
  center: new L.LatLng(lat, lon),
  zoom: 13,
  minZoom: 4
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

    const Stricken_Area = L.tileLayer.wms("http://127.1.1.1:8080/geoserver/vector/wms/", {
    layers: 'vector:m1_stricken_area',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 3
    });

    const TimeMap = L.tileLayer.wms("http://127.1.1.1:8080/geoserver/vector/wms/", {
    layers: 'vector:m1_time_map',
    format: 'image/png',
    transparent: true,
    legend_yes: true,
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

    const AccessibilityMap = L.tileLayer.wms("http://127.1.1.1:8080/geoserver/vector/wms/", {
    layers: 'vector:m1b_accessibility_map',
    format: 'image/png',
    transparent: true,
    legend_yes: true,
    maxZoom: 20,
    minZoom: 3
    });
    
    const AccessibilityPoints = L.tileLayer.wms("http://127.1.1.1:8080/geoserver/vector/wms/", {
    layers: 'vector:m1b_points',
    format: 'image/png',
    transparent: true,
    maxZoom: 20,
    minZoom: 3
    });
        
    
 // Local layers (Bhubaneshwar)
 // Watch out the property 'legend_yes'. It must be  true if you want to allow a second checckbox to display (refer to views/launch/legend.js and views/index.pug)   
    
            const Bbswr_Metropolitan_Area = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                layers: 'vector:bubaneshwar_metropolitan_area',
                format: 'image/png',
                transparent: true,
                legend_yes: true,
                maxZoom: 20,
                minZoom: 1,
            });
            
            const Bbswr_City_Zone = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bubaneshwar_city_zone',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
    
            const Slum_Areas = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_slums',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
            const Slum_Total_Population = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_slum_total_population_households',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
                
            const Female_Population = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_slum_female_population_households',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
                
            const Male_Population = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_slum_male_population_households',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
            const Empty_Place_Types = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_empty_place_types',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
                
            const Empty_Place_Category= L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_empty_places_category',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
                
            const Land_Ownership = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:land_owners',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
                
            const Slums_Empty_Ownership = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:empty_places_ownership',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
                
            const Slum_Ownerhip = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: '	vector:bbswr_slum_ownership',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
                
            const Slum_Religions = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_slum_religions',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
                
            const Monthly_Incomes = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_slum_average_incomes',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });            
                
            const Animals = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_slum_animals',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
                
            const Slums_Bathrooms = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_slum_bathrooms',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
                
            const Slum_Tapwater = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_slum_tapwater',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
                
            const Slum_Toilettes = L.tileLayer.wms(geoserverUrl + 'geoserver/vector/wms', {
                    layers: 'vector:bbswr_slum_toilettes',
                    format: 'image/png',
                    transparent: true,
                    legend_yes: true,
                    maxZoom: 20,
                    minZoom: 1,
                });
    
//Control for map legends. For those item, where the linked map has a "legend_yes: true," property, a second checkbox will displayed.
            
L.control.legend(
    {
        position:'bottomleft'
        
    }
).addTo(map);

// Control panel of base layers 
L.control.layers(
  {},
  {
    'OpenStreetMap': osm,
    'Water lines': waterLines,
    'Roads': roads,
    'Buildings': buildings,
    'Current selection': selection,
    'Drawings on the map': drawnItems
  },
  { position: 'topright', collapsed: false }
).addTo(map);


// Control panel of extension layers 
L.control.layers(
  {},
  {
    'Query area 1': query_area_1,
    'Query results 1': query_result_area_1,
    'Query results 3': query_result_point_1,
    "Road-level time map": TimeMap,
    "From-points": FromPoints,
    "Via-points": ViaPoints,
    "Stricken area": Stricken_Area,
    "Accessibility map": AccessibilityMap,
    "Accessing points": AccessibilityPoints,
    },
  { position: 'topright', collapsed: false }
).addTo(map);


// Control panel for local layers

          L.control.layers(
        {},
        {
            "Bubaneshwar metropolitan area":Bbswr_Metropolitan_Area,
            "Bubaneshwar city zone":Bbswr_City_Zone,
            "Slums of Bubaneshwar":Slum_Areas,
            "Total population by households":Slum_Total_Population,
            "Female habitanst by households":Female_Population,
            "Male habitanst by households":Male_Population,
            "Open/Vacant empty places":Empty_Place_Types,
            "Dry/Green empty places ":Empty_Place_Category,
            "Land ownership in Bubaneshwar":Land_Ownership,
            "Ownership of empty areas":Slums_Empty_Ownership,
            "Ownerhips of slum houses":Slum_Ownerhip,
            "Religions by households":Slum_Religions,
            "Monthly average incomes per household":Monthly_Incomes,
            "Household with/without livestocks":Animals,
            "Bathroom facilities in the slums":Slums_Bathrooms,
            "Water accessibility in slums":Slum_Tapwater,
            "Toilette facilities in the slums":Slum_Toilettes,
        },
        { position: 'topright', collapsed: true }).addTo(map);





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
L.control.scale({ maxWidth: 300, position:'bottomright'}).addTo(map);

/* north arrow */
const north = L.control({ position: 'bottomright' });
north.onAdd = () => document.getElementById('north-arrow');
north.addTo(map);

