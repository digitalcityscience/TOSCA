import React, { useContext } from 'react';
import PropTypes from 'prop-types';

import { StepsContext } from './steps-context';

export const Step = ({ id, className, step, children }) => {
  const { currentStep } = useContext(StepsContext);
  return step === currentStep ? <div id={id} className={className}>{children}</div> : null;
};

Step.propTypes = {
  id: PropTypes.string,
  className: PropTypes.string,
  step: PropTypes.string.isRequired,
  children: PropTypes.oneOfType([
    PropTypes.node,
    PropTypes.arrayOf(PropTypes.node),
  ]).isRequired,
};

Step.defaultProps = {
  id: null,
  className: null,
};