import React, { useEffect } from 'react';
import L from 'leaflet';
import 'leaflet-draw';
import 'leaflet-groupedlayercontrol';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw/dist/leaflet.draw.css';

import { GlobalContext } from '../../store/global';
import './styles/style.css';

export const MapView = () => {
  const { setDrawings } = React.useContext(GlobalContext);

  // this hook only run once on component mount
  // making sure the leaflet map container doesn't change with any react state change
  useEffect(() => {
    const map = new L.Map('map', {
      center: new L.LatLng(
        process.env.LATITUDE,
        process.env.LONGITUDE
      ),
      zoom: 13,
      minZoom: 4,
      touchZoom: true
    });

    /* Create background maps */
    const osm = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    const hot = L.tileLayer('https://tile-{s}.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors; Humanitarian map style by <a href="https://www.hotosm.org/">HOT</a>'
    });

    /* Set up grouped layer control */
    const baseLayers = {
      "OSM Standard style": osm,
      "OSM Humanitarian style": hot
    };

    L.control.groupedLayers(baseLayers, {}, { position: 'topright', collapsed: false }).addTo(map);

    /* Drawing tool */
    const drawings = L.featureGroup().addTo(map);

    setDrawings(drawings);

    map.addControl(new L.Control.Draw({
      edit: {
        featureGroup: drawings,
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

    // Save drawn items in feature group
    map.on(L.Draw.Event.CREATED, event => {
      drawings.addLayer(event.layer);
    });

    /* Scale bar */
    L.control.scale({ maxWidth: 300, position: 'bottomright' }).addTo(map);

  }, []);

  return (
    <div id="map"></div>
  );
};
