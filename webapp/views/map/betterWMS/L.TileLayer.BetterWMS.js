/* global L, $ */

L.TileLayer.BetterWMS = L.TileLayer.WMS.extend({

  onAdd: function (map) {
    // Triggered when the layer is added to a map.
    //   Register a click listener, then do all the upstream WMS things
    L.TileLayer.WMS.prototype.onAdd.call(this, map);
    map.on('click', this.getFeatureInfo, this);
  },

  onRemove: function (map) {
    // Triggered when the layer is removed from a map.
    //   Unregister a click listener, then do all the upstream WMS things
    L.TileLayer.WMS.prototype.onRemove.call(this, map);
    map.off('click', this.getFeatureInfo, this);
  },

  getFeatureInfo: function (evt) {
    // Make an AJAX request to the server and hope for the best
    const url = this.getFeatureInfoUrl(evt.latlng),
      showResults = L.Util.bind(this.showGetFeatureInfo, this);
    $.ajax({
      url: url,
      success: function (data) {
        const content = typeof data === 'string' ? null : data;
        showResults(content, evt.latlng, data);
      },
      error: function (xhr, status, error) {
        showResults(error);
      }
    });
  },

  getFeatureInfoUrl: function (latlng) {
    // Construct a GetFeatureInfo request URL given a point
    const point = this._map.latLngToContainerPoint(latlng, this._map.getZoom()),
      size = this._map.getSize(),
      params = {
        request: 'GetFeatureInfo',
        service: 'WMS',
        srs: 'EPSG:4326',
        styles: this.wmsParams.styles,
        transparent: this.wmsParams.transparent,
        version: this.wmsParams.version,
        format: this.wmsParams.format,
        bbox: this._map.getBounds().toBBoxString(),
        height: size.y,
        width: size.x,
        layers: this.wmsParams.layers,
        // eslint-disable-next-line camelcase
        query_layers: this.wmsParams.layers,
        // eslint-disable-next-line camelcase
        info_format: 'application/json'
      };
    params[params.version === '1.3.0' ? 'i' : 'x'] = Math.round(point.x);
    params[params.version === '1.3.0' ? 'j' : 'y'] = Math.round(point.y);

    return this._url + L.Util.getParamString(params, this._url, true);
  },

  showGetFeatureInfo: function (content, latlng) {
    if (content.features.length == 0) {
      return
    }
    // Otherwise show the content in a popup, or something.
    else {
      L.popup({ maxWidth: 'auto' })
        .setLatLng(latlng)
        .setContent(getTableHTML(content.features[0].properties, content.features[0].id))
        .openOn(this._map);
    }
  }
});

function getTableHTML(properties, name) {
  let html = "<div class='getFeatureClass'>" + "<p>" + name + "</p>"
  html += "<table><tbody>";

  for (let key in properties) {
    let value = properties[key]
    if (properties[key] !== null && key !== 'cat') {
      html += "<tr><td>" + key + "</td>"
      html += "<td>" + value + "</td></tr>"
    }
  }

  html = html + "</tbody></table></div>";
  return html;
}

L.tileLayer.betterWms = function (url, options) {
  return new L.TileLayer.BetterWMS(url, options);
};