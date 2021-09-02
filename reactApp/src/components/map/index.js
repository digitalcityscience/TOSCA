import React, { useEffect } from 'react';
import L from 'leaflet';

import 'leaflet-draw';
import 'leaflet-groupedlayercontrol';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw/dist/leaflet.draw.css';
import './styles/style.css';

import { GlobalContext } from '../../store/global';
import { useLayerControl } from './hooks/use-layer-control';

let map = {};

export const MapView = () => {
  const { setDrawings } = React.useContext(GlobalContext);

  // this hook only run once on component mount
  // making sure the leaflet map container doesn't change with any react state change
  useEffect(() => {
    map = new L.Map('map', {
      center: new L.LatLng(
        process.env.LATITUDE,
        process.env.LONGITUDE
      ),
      zoom: 13,
      minZoom: 4,
      touchZoom: true
    });
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

  useLayerControl(map);

  return (
    <div id="map"></div>
  );
};
