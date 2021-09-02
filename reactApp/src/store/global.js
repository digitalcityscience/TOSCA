import React, { useReducer } from 'react';
import PropTypes from 'prop-types';

import { WPS } from './wps';
import { geoserverREST } from './geoserver-rest';

export const GlobalContext = React.createContext();

const initialState = {
  dialogMessage: '',
  activeModule: null,
  activeModuleStep: 0,
  drawings: null,
  WPS,
  geoserverREST,
};
const actions = {
  SET_DIALOG_MESSAGE: 'SET_DIALOG_MESSAGE',
  SET_ACTIVE_MODULE: 'SET_ACTIVE_MODULE',
  SET_DRAWINGS: 'SET_DRAWINGS'
};

const reducer = (state, action) => {
  switch (action.type) {
    case 'SET_DIALOG_MESSAGE':
      return { ...state, dialogMessage: action.value };
    case 'SET_ACTIVE_MODULE':
      return { ...state, activeModule: action.module, activeModuleStep: action.step };
    case 'SET_DRAWINGS':
      return { ...state, drawings: action.featureGroup };
    default:
      return state;
  }
};

export const GlobalContextProvider = ({ children }) => {
  const [state, dispatch] = useReducer(reducer, initialState);

  const value = {
    dialogMessage: state.dialogMessage,
    activeModule: state.activeModule,
    activeModuleStep: state.activeModuleStep,
    drawings: state.drawings,
    WPS: state.WPS,
    geoserverREST: state.geoserverREST,
    setDialogMessage: (value) => {
      dispatch({ type: actions.SET_DIALOG_MESSAGE, value });
    },
    setActiveModule: (module, step) => {
      dispatch({ type: actions.SET_ACTIVE_MODULE, module, step });
    },
    setDrawings: (featureGroup) => {
      dispatch({ type: actions.SET_DRAWINGS, featureGroup });
    }
  };

  return (
    <GlobalContext.Provider value={value}>
      {children}
    </GlobalContext.Provider>
  );
};

GlobalContextProvider.propTypes = {
  children: PropTypes.oneOfType([
    PropTypes.object,
    PropTypes.array
  ]).isRequired,
};
