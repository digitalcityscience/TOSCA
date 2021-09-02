const baseURL = process.env.GEOSERVER_URL + 'geoserver/rest/';
const ACCESS_CODE = btoa(`${process.env.GEOSERVER_USERNAME}:${process.env.GEOSERVER_PASSWORD}`);

const headers = new Headers({
  'Authorization': `Basic ${ACCESS_CODE}`
});

export const geoserverREST = {
  /**
   * Gets all featureTypes(layers) information stored in a specific workspace
   * @param {string} workspace name of the workspace, e.g. 'vector'. 
   */
  GetFeatureTypesInWorkspace: (workspace) => {
    return fetch(baseURL + `workspaces/${workspace}/featuretypes.json`, { headers })
      .then(response => response.json())
      .then(data => data.featureTypes.featureType);
  },

  /**
   * Gets information about one particular featureType(layer)
   * @param {string} workspace name of the workspace, e.g. 'vector'. 
   * @param {string} name name of the layer, e.g. 'basemap_bbox'. 
   */
  GetFeatureType: (workspace, name) => {
    return fetch(baseURL + `workspaces/${workspace}/featuretypes/${name}.json`, { headers })
      .then(response => response.json())
      .then(data => data.featureType);
  },
};
