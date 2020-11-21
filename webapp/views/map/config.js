const services = {
    // Basemap
    waterways: {
        layers: 'osm_waterways',
        format: 'image/png',
        transparent: true,
        maxZoom: 20,
        minZoom: 1,
        displayName: 'Waterways',
        type: 'vector'
    },
    roads: {
        layers: 'osm_roads',
        format: 'image/png',
        transparent: true,
        maxZoom: 20,
        minZoom: 1,
        displayName: 'Roads',
        type: 'vector'
    },
    buildings: {
        layers: 'osm_buildings',
        format: 'image/png',
        transparent: true,
        maxZoom: 20,
        minZoom: 1,
        displayName: 'Buildings',
        type: 'vector'
    },
    basemapBbox: {
        layers: 'basemap_bbox',
        format: 'image/png',
        transparent: true,
        maxZoom: 20,
        minZoom: 1,
        displayName: 'Basemap boundary',
        type: 'vector'
    },
    // Selection
    selection: {
        layers: 'selection',
        format: 'image/png',
        transparent: true,
        maxZoom: 20,
        minZoom: 1,
        displayName: 'Current selection',
        type: 'vector'
    },
    // Time map module
    fromPoints: {
        layers: 'time_map_from_points',
        format: 'image/png',
        transparent: true,
        maxZoom: 20,
        minZoom: 3,
        displayName: 'Start point',
        type: 'vector'
    },
    viaPoints: {
        layers: 'time_map_via_points',
        format: 'image/png',
        transparent: true,
        maxZoom: 20,
        minZoom: 3,
        displayName: 'Via point',
        type: 'vector'
    },
    strickenArea: {
        layers: 'time_map_stricken_area',
        format: 'image/png',
        transparent: true,
        maxZoom: 20,
        minZoom: 3,
        displayName: 'Affected area',
        type: 'vector'
    },
    timeMap: {
        layers: 'time_map_result',
        format: 'image/png',
        transparent: true,
        legend: true,
        maxZoom: 20,
        minZoom: 1,
        displayName: 'Road-level time map',
        type: 'raster'
    }
}