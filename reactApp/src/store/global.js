import React, { useReducer } from 'react';
import PropTypes from 'prop-types';

import { WPS } from './wps';

export const GlobalContext = React.createContext();

const initialState = {
  dialogMessage: '',
  activeModule: null,
  activeModuleStep: 0,
  WPS: WPS
};
const actions = {
  SET_DIALOG_MESSAGE: 'SET_DIALOG_MESSAGE',
  SET_ACTIVE_MODULE: 'SET_ACTIVE_MODULE',
};

const reducer = (state, action) => {
  switch (action.type) {
    case 'SET_DIALOG_MESSAGE':
      return { ...state, dialogMessage: action.value };
    case 'SET_ACTIVE_MODULE':
      return { ...state, activeModule: action.module, activeModuleStep: action.step };
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
    WPS: state.WPS,
    setDialogMessage: (value) => {
      dispatch({ type: actions.SET_DIALOG_MESSAGE, value });
    },
    setActiveModule: (module, step) => {
      dispatch({ type: actions.SET_ACTIVE_MODULE, module, step });
    },
  };

  return (
    <GlobalContext.Provider value={value}>
      {children}
    </GlobalContext.Provider>
  );
};

GlobalContextProvider.propTypes = {
  children: PropTypes.object.isRequired,
};
