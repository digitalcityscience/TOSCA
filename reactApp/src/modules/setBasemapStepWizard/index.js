import React, { useState } from 'react';

import { GlobalContext } from '../../store/global';
import { StepsContainer, Step, StepsFooter } from '../../components/controls/steps';
import { useLoading } from '../../store/loading';
import { useAlert } from '../../store/alert';

export const SetBasemapModule = () => {
  const { setActiveModule, WPS } = React.useContext(GlobalContext);

  const basemapForm = React.createRef();
  const steps = ['introduction', 'selectMap'];
  const [currentStepIndex, setCurrentStepIndex] = useState(0);

  const { showLoading, hideLoading } = useLoading();
  const { addAlert } = useAlert();

  const moveForward = () => {
    setCurrentStepIndex(prev => prev + 1);
  };

  const moveBack = () => {
    setCurrentStepIndex(prev => prev - 1);
  };

  const onSubmit = async () => {
    const formData = new FormData(basemapForm.current);

    try {
      showLoading();
      const response = await WPS.upload(formData);
      await WPS.Execute('set_basemap', [{ identifier: 'filename', data: response }]);
      setActiveModule(null);
    } catch (err) {
      addAlert({ message: err.message });
      console.error(err.message);
    }
    hideLoading();
  };

  return (
    <StepsContainer steps={steps} currentStep={steps[currentStepIndex]}>
      <Step step={steps[0]}>
        <div>
          If you set a new basemap, the existing basemap will be overwritten. Do you want to set a new basemap?
        </div>
        <StepsFooter onClickNext={moveForward} nextText="Yes" cancelText="No"></StepsFooter>
      </Step>
      <Step step={steps[1]}>
        <div>
          Select an OpenStreetMap (.osm) file to use as the basemap. You can download an OSM file from <a href="https://www.openstreetmap.org/" target="_blank" rel="noreferrer">openstreetmap.org</a>; see the manual for further help.
          <br />
          <small>Setting a new basemap may take a long time if the file is large.</small>
          <form ref={basemapForm} encType="multipart/form-data">
            <input type="file" name="file" />
          </form>
        </div>
        <StepsFooter onClickBack={moveBack} onClickSubmit={onSubmit}></StepsFooter>
      </Step>
    </StepsContainer>
  );
};
