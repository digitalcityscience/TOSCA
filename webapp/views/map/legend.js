// Author: FARKAS Gábor,
// University of Pécs, Hungary
// 2020, 2 July,

(function () {
    // Hacking layer controlt, to create a 2nd checkboxot too.
    const layerAddOrigFunc = L.Control.GroupedLayers.prototype._addItem;
    L.Control.GroupedLayers.prototype._addItem = function (obj) {
        // The original functionality -- of course -- preserved and called :)
        const label = layerAddOrigFunc.call(this, obj);
        // Only for WMS -- otherwise it has no sense.
        if (obj.layer instanceof L.TileLayer.WMS && obj.layer.options.legend_yes) {
            label.children[0].addEventListener('click', handleLegendClick.bind(obj.layer));
        }
        return label;
    }

    // Legend control -- the previous link will binded to
    L.Control.Legend = L.Control.extend({
        // This will run when adding to the map.
        onAdd: function (map) {
            // This is a base div, containing the legends
            const div = L.DomUtil.create('div');
            div.id = 'leaflet-legend-container';
            div.className = 'leaflet-legend';
            return div;
        },

        // It is not necessary to remove, it would be pointless
        onRemove: function (map) { }
    });

    // A comfot function in Leaflet style
    L.control.legend = function (opts) {
        return new L.Control.Legend(opts);
    }

    // Actual linking to  'legend control'. The 'this' contains the layer, and the 'evt.target' contains the checkbox.
    function handleLegendClick(evt) {
        const container = document.getElementById('leaflet-legend-container');
        if (evt.target.checked) {
            const div = L.DomUtil.create('div')
            div.id = this.wmsParams.layers
            div.className = 'leaflet-legend-item'
            container.appendChild(div)

            const p = L.DomUtil.create('p')
            p.className = 'leaflet-legend-layer-name'
            p.innerHTML = this.options.name
            div.appendChild(p)

            const img = L.DomUtil.create('img')
            img.style = 'display:block;'
            img.src = this._url + '?SERVICE=WMS&REQUEST=GetLegendGraphic&VERSION=1.0.0&FORMAT=image/png&WIDTH=20&HEIGHT=20&LAYER=' + this.wmsParams.layers;
            div.appendChild(img)
        } else {
            const img = document.getElementById(this.wmsParams.layers);
            if (img && container.contains(img)) {
                container.removeChild(img);
            }
        }
    }
}());
