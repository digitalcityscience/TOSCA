import React, { useState } from 'react';
import 'bootstrap/dist/css/bootstrap.min.css';
import 'bootstrap/dist/js/bootstrap.bundle.min';

import { MapView } from './map';
import { NavbarView } from './navbar';
import { SidebarView } from './sidebar';
import { ResultModal } from './modals/result-modal';
import { AlertContainer } from './common/alert-container';
import { LoadingContainer } from './common/loading-container';

import './styles/style.css';

export const Root = () => {
  const [showModal, setShowModal] = useState(false);

  const onResultClicked = () => {
    setShowModal(true);
  };

  const onResultModalCloseClicked = () => {
    setShowModal(false);
  };

  return (
    <>
      <div className="d-flex flex-column h-100">
        <div className="card box-shadow">
          <NavbarView onResultClicked={onResultClicked} />
        </div>
        <div className="d-flex flex-grow-1 main">
          <div id="sidebar" className="d-flex flex-column w-25 sidebar">
            <SidebarView />
          </div>
          <div id="map-container" className="col card box-shadow">
            <MapView />
          </div>
        </div>
        <AlertContainer />
        <LoadingContainer />
      </div>
      {showModal && <ResultModal onCloseClicked={onResultModalCloseClicked} />}
    </>
  );
};
