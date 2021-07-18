import React from 'react';
import PropTypes from 'prop-types';

import { StepsContext } from './steps-context';

export const StepsContextProvider = ({ steps, currentStep, children }) => {
  const value = { currentStep, steps };
  return (
    <StepsContext.Provider value={value}>
      {children}
    </StepsContext.Provider>
  );
};

StepsContextProvider.propTypes = {
  steps: PropTypes.arrayOf(PropTypes.string).isRequired,
  currentStep: PropTypes.string.isRequired,
  children: PropTypes.oneOfType([
    PropTypes.node,
    PropTypes.arrayOf(PropTypes.node),
  ]).isRequired,
};
