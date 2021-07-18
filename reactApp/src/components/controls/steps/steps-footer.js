import React, { useContext } from 'react';
import PropTypes from 'prop-types';

import { StepPositions } from './utils';
import { StepsContext } from './steps-context';

// TODO: 1. how to control show/not show
// 2. how to control disabled/not disabled
export const StepsFooter = ({
  onClickBack, onClickNext, onClickSubmit
}) => {
  const { currentStep, steps } = useContext(StepsContext);
  return (
    <React.Fragment>
      { currentStep !== StepPositions.getFirst(steps) &&
        <button className='btn-back btn-primary' onClick={onClickBack}>Back</button>
      }
      { currentStep !== StepPositions.getLast(steps) &&
        <button className='btn-next btn-primary' onClick={onClickNext}>Next</button>
      }
      { currentStep === StepPositions.getLast(steps) &&
        <button className='btn-submit btn-primary' onClick={onClickSubmit}>Submit</button>
      }
    </React.Fragment>
  );
};

StepsFooter.propTypes = {
  onClickBack: PropTypes.func,
  onClickNext: PropTypes.func,
  onClickSubmit: PropTypes.func,
};

StepsFooter.defaultProps = {
  onClickBack: () => { },
  onClickNext: () => { },
  onClickSubmit: () => { },
};
