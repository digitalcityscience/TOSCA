import React from 'react';
import PropTypes from 'prop-types';

import 'bootstrap/dist/css/bootstrap.min.css';
import 'bootstrap/dist/js/bootstrap.bundle.min';

import './styles/style.css';

const parseWPSResponse = (response) => {
  return response.text().then(text => {
    const parser = new DOMParser();
    const document = parser.parseFromString(text, 'text/xml');
    if (document.getElementsByTagName("ows:Exception").length) {
      throw new Error("Error: " + document.getElementsByTagName("ows:ExceptionText")[0].textContent);
    }
    return document;
  });
};

const testWPS = () => {
  fetch('http://localhost:5000/wps?service=WPS&version=1.0.0&request=Execute&identifier=say_hello&dataInputs=name=React')
    .then(response => parseWPSResponse(response))
    .then(document => {
      alert(document
        .getElementsByTagName("wps:ProcessOutputs")[0]
        .getElementsByTagName("wps:Output")[0]
        .getElementsByTagName("wps:Data")[0]
        .getElementsByTagName("wps:LiteralData")[0]
        .textContent);
    })
    .catch(err => {
      console.error(err.message);
    });
};

const setResolution = () => {
  let resolution = 10;

  fetch(`http://localhost:5000/wps?service=WPS&version=1.0.0&request=Execute&identifier=set_resolution&dataInputs=resolution=${resolution}`)
    .then(response => parseWPSResponse(response))
    .then(() => {
      console.log("OK");
    })
    .catch(err => {
      console.error(err.message);
    });
};

export const NavbarView = ({ onResultClicked }) => (
  <nav className="navbar navbar-expand navbar-light">
    <div className="navbar-brand fw-bold">Open City Toolkit</div>
    <ul className="navbar-nav flex-grow-1 justify-content-space-evenly">
      <li className="nav-item d-flex align-items-center">
        <span className="d-inline-block align-middle m-2">Modules</span>
        <select defaultValue="time_map" id="launch-module-menu" className="form-select form-select-lg me-2">
          <option value="time_map">Calculate time map</option>
          <option value="query">Query area</option>
        </select>
        <button className="btn btn-success btn-lg me-2" onClick={() => { }}>▷&nbsp;Run</button>
        <button className="btn btn-light btn-lg" id="result-btn" onClick={onResultClicked}>Results</button>
      </li>
      <li className="nav-item flex-grow-1" />
      <li className="nav-item d-flex align-items-center">
        <div className=" dropdown">
          <a className="btn btn-light btn-lg dropdown-toggle" id="settings-menu" role="button" data-bs-toggle="dropdown">Settings</a>
          <ul className="dropdown-menu" aria-labelledby="settings-menu">
            <li>
              <a className="btn dropdown-item" onClick={testWPS}>Test WPS</a>
            </li>
            <li>
              <a className="btn dropdown-item" onClick={() => { }}>Set basemap</a>
            </li>
            <li>
              <a className="btn dropdown-item" onClick={() => { }}>Set selection</a>
            </li>
            <li>
              <a className="btn dropdown-item" onClick={setResolution}>Set resolution</a>
            </li>
            <li>
              <a className="btn dropdown-item" onClick={() => { }}>Add layer</a>
            </li>
          </ul>
        </div>
      </li>
      <li className="nav-item">
        <a className="btn btn-secondary btn-lg" href="https://github.com/citysciencelab/open-city-toolkit/wiki">
          Help
        </a>
      </li>
    </ul>
  </nav>
);

NavbarView.propTypes = {
  onResultClicked: PropTypes.func.isRequired,
};
