import React from 'react';
import PropTypes from 'prop-types';

import { StepsContext } from './steps-context';

export const StepsContainer = ({ steps, currentStep, children }) => (
  <StepsContext.Provider value={{ currentStep, steps }}>
    {children}
  </StepsContext.Provider>
);

StepsContainer.propTypes = {
  steps: PropTypes.arrayOf(PropTypes.string).isRequired,
  currentStep: PropTypes.string.isRequired,
  children: PropTypes.oneOfType([
    PropTypes.node,
    PropTypes.arrayOf(PropTypes.node),
  ]).isRequired,
};
