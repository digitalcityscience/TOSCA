import React, { useState, useCallback, useContext } from 'react';
import PropTypes from 'prop-types';

export const LoadingContext = React.createContext();

export const LoadingContextProvider = ({ children }) => {
  const [isLoading, setIsLoading] = useState(false);
  const hideLoading = useCallback(() => setIsLoading(false), []);
  const showLoading = useCallback(() => setIsLoading(true), []);
  const initialValue = {
    isLoading,
    hideLoading,
    showLoading
  };

  return (
    <LoadingContext.Provider value={initialValue}>
      {children}
    </LoadingContext.Provider>
  );
};

LoadingContextProvider.propTypes = {
  children: PropTypes.oneOfType([
    PropTypes.object,
    PropTypes.array
  ]).isRequired,
};

export const useLoading = () => {
  const { isLoading, hideLoading, showLoading } = useContext(LoadingContext);
  return { isLoading, hideLoading, showLoading };
};
