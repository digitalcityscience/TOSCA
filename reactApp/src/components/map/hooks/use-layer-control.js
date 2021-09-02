import React, { useEffect } from 'react';
import L from 'leaflet';

import { GlobalContext } from '../../../store/global';
import { useAlert } from '../../../store/alert';

const geoserverUrl = process.env.GEOSERVER_URL;
const rasterWMS = geoserverUrl + 'geoserver/raster/wms';
const vectorWMS = geoserverUrl + 'geoserver/vector/wms';

/* Create background maps */
const osm = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
});
const hot = L.tileLayer('https://tile-{s}.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors; Humanitarian map style by <a href="https://www.hotosm.org/">HOT</a>'
});
/* Set up grouped layer control */
const baseLayers = {
  "OSM Standard style": osm,
  "OSM Humanitarian style": hot
};

const geoserverWorkspaces = ['vector'];
/**
 * Create WMS service based on layer config
 * @param {object} layer layer from config.js
 */
function createWms(layer) {
  if (layer.type === 'vector') {
    return L.tileLayer.wms(vectorWMS, layer);
  }
  if (layer.type === 'raster') {
    return L.tileLayer.wms(rasterWMS, layer);
  }
}

export const useLayerControl = (map) => {
  const { geoserverREST } = React.useContext(GlobalContext);
  const { addAlert } = useAlert();

  // this useEffect watches the global map object and only runs when map is intialized.
  useEffect(async () => {
    if (Object.keys(map).length > 0) {
      osm.addTo(map);

      let overlayMaps = {};
      try {
        const featureTypes = await Promise.all(geoserverWorkspaces.map(workspace => geoserverREST.GetFeatureTypesInWorkspace(workspace))).then(results => results.flat());
        const featureTypeNames = featureTypes.map(ft => ft.name);
        const featureTypeInfos = await Promise.all(featureTypeNames.map(name => geoserverREST.GetFeatureType('vector', name)));
       
        const layersConfig = featureTypeInfos.map(info => ({
          layers: info.name,
          format: 'image/png',
          transparent: true,
          maxZoom: 20,
          minZoom: 1,
          title: info.title,
          type: 'vector', // TODO: get resource type (vector/raster) from geoserver API
        }));
        for (const layer of layersConfig) {
          overlayMaps[layer.title] = createWms(layer);
        }
      } catch (err) {
        addAlert({ message: err.message });
        console.error(err.message);
      }

      L.control.layers(baseLayers, overlayMaps).addTo(map);
    }
  }, [map]);
};
