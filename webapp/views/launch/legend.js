// Author: FARKAS Gábor,
// University of Pécs, Hungary
// 2020, 2 July,

(function () {
    // Hacking layer controlt, to create a 2nd checkboxot too.
    const layerAddOrigFunc = L.Control.Layers.prototype._addItem;
    L.Control.Layers.prototype._addItem = function(obj) {
        // The original functionality -- of course -- preserved and called :)
        const label = layerAddOrigFunc.call(this, obj);
        // Only for WMS -- otherwise it has no sense.
        if (obj.layer instanceof L.TileLayer.WMS && obj.layer.options.legend_yes) {
            const holder = label.children[0];

            const input = document.createElement('input');
            input.type = 'checkbox';
			input.className = 'leaflet-control-layers-selector';
            input.defaultChecked = false;

            // Linking the layer, making accessible as 'this', by the watcher
            input.addEventListener('click', handleLegendClick.bind(obj.layer));
            
            holder.insertBefore(input, holder.lastChild);
        }

        return label;
    }

    // Legend control -- the previous link will binded to
    L.Control.Legend = L.Control.extend({
        // This will run when adding to the map.
        onAdd: function(map) {
            // This is a base div, containing the legends
            const div = L.DomUtil.create('div');
            div.id = 'leaflet-legend-container';
            div.className = 'leaflet-legend';

            return div;
        },

        // It is not necessary to remove, it would be pointless
        onRemove: function(map) {}
    });

    // A comfot function in Leaflet style
    L.control.legend = function(opts) {
        return new L.Control.Legend(opts);
    }

    // Actual linking to  'legend control'. The 'this' contains the layer, and the 'evt.target' contains the checkbox.
    function handleLegendClick(evt) {
        const container = document.getElementById('leaflet-legend-container');

        if (evt.target.checked) {
            // The legend image
            const img = L.DomUtil.create('img');
            img.src = this._url + '?SERVICE=WMS&REQUEST=GetLegendGraphic&VERSION=1.0.0&FORMAT=image/png&WIDTH=20&HEIGHT=20&LAYER=' + this.wmsParams.layers;
            // the layer name will serve as ID, allowing to remove when user deselect the checkbox
            img.id = this.wmsParams.layers;
            container.appendChild(img);
        } else {
            const img = document.getElementById(this.wmsParams.layers);
            if (img && container.contains(img)) {
                container.removeChild(img);
            }
        }
    }
}());
