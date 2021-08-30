import React, { useState, useCallback, useContext } from 'react';
import PropTypes from 'prop-types';
import { v4 as uuidv4 } from 'uuid';

export const AlertContext = React.createContext();

export const AlertContextProvider = ({ children }) => {
  const [alerts, setAlerts] = useState([]);
  const removeAlert = useCallback((id) => setAlerts(prev => prev.filter(alert => alert.id !== id)), []);
  const addAlert = useCallback(({ message }) => setAlerts(prev => [...prev, { message, id: uuidv4() }]), []);
  const initialValue = {
    alerts,
    addAlert,
    removeAlert
  };

  return (
    <AlertContext.Provider value={initialValue}>
      {children}
    </AlertContext.Provider>
  );
};

AlertContextProvider.propTypes = {
  children: PropTypes.oneOfType([
    PropTypes.object,
    PropTypes.array
  ]).isRequired,
};

export const useAlert = () => {
  const { alerts, addAlert, removeAlert } = useContext(AlertContext);
  return { alerts, addAlert, removeAlert };
};
