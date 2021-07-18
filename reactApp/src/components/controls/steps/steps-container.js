import React from 'react';
import PropTypes from 'prop-types';

import { StepsContextProvider } from './steps-context-provider';

export const StepsContainer = ({ id, className, steps, currentStep, children }) => {
  const container = (
    <div id={id} className={className}>
      {children}
    </div>
  );
  return (
    <StepsContextProvider currentStep={currentStep} steps={steps}>
      {container}
    </StepsContextProvider>
  );
};

StepsContainer.propTypes = {
  id: PropTypes.string,
  className: PropTypes.string,
  steps: PropTypes.arrayOf(PropTypes.string).isRequired,
  currentStep: PropTypes.string.isRequired,
  children: PropTypes.oneOfType([
    PropTypes.node,
    PropTypes.arrayOf(PropTypes.node),
  ]).isRequired,
};

StepsContainer.defaultProps = {
  id: null,
  className: null,
};
