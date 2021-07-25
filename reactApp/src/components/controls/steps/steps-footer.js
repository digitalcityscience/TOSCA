import React, { useContext } from 'react';
import PropTypes from 'prop-types';

import { StepPositions } from './utils';
import { StepsContext } from './steps-context';
import { GlobalContext } from '../../../store/global';

// TODO: how to control disabled/not disabled
export const StepsFooter = ({
  onClickBack, onClickNext, onClickSubmit,
  backText, nextText, submitText, cancelText
}) => {
  const { setActiveModule } = useContext(GlobalContext);
  const { currentStep, steps } = useContext(StepsContext);
  return (
    <React.Fragment>
      { currentStep !== StepPositions.getFirst(steps) &&
        <button className='btn-back btn-primary' onClick={onClickBack}>{backText || 'Back'}</button>
      }
      { currentStep !== StepPositions.getLast(steps) &&
        <button className='btn-next btn-primary' onClick={onClickNext}>{nextText || 'Next'}</button>
      }
      { currentStep === StepPositions.getLast(steps) &&
        <button className='btn-submit btn-primary' onClick={onClickSubmit}>{submitText || 'Submit'}</button>
      }
      <button className='btn-submit btn-primary' onClick={() => setActiveModule(null)}>{cancelText || 'Cancel'}</button>
    </React.Fragment>
  );
};

StepsFooter.propTypes = {
  onClickBack: PropTypes.func,
  onClickNext: PropTypes.func,
  onClickSubmit: PropTypes.func,
  backText: PropTypes.string,
  nextText: PropTypes.string,
  submitText: PropTypes.string,
  cancelText: PropTypes.string,
};

StepsFooter.defaultProps = {
  onClickBack: () => { },
  onClickNext: () => { },
  onClickSubmit: () => { },
  backText: null,
  nextText: null,
  submitText: null,
  cancelText: null,
};
