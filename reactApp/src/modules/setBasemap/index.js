import React from 'react';
import PropTypes from 'prop-types';

import { GlobalContext } from '../../store/global';

const MessageView1 = ({ setStep }) => {
  const { setActiveModule } = React.useContext(GlobalContext);

  return (
    <>
      <div>
        If you set a new basemap, the existing basemap will be overwritten. Do you want to set a new basemap?
      </div>
      <div className="btn-group">
        <button type="button" className="btn btn-primary" onClick={() => setStep(1)}>Yes</button>
        <button type="button" className="btn btn-secondary" onClick={() => setActiveModule(null)}>No</button>
      </div>
    </>
  );
};

MessageView1.propTypes = {
  setStep: PropTypes.func.isRequired
};

const MessageView2 = ({ setStep }) => {
  const { setActiveModule, WPS } = React.useContext(GlobalContext);
  const basemapForm = React.createRef();

  const submit = async () => {
    const formData = new FormData(basemapForm.current);

    try {
      const response = await WPS.upload(formData);
      await WPS.Execute('set_basemap', [{identifier: 'filename', data: response}]);
      setStep(2);
    } catch (err) {
      console.error(err.message);
    }
  };

  return (
    <>
      <div>
        Select an OpenStreetMap (.osm) file to use as the basemap. You can download an OSM file from <a href="https://www.openstreetmap.org/" target="_blank" rel="noreferrer">openstreetmap.org</a>; see the manual for further help.
        <br />
        <small>Setting a new basemap may take a long time if the file is large.</small>
        <form ref={basemapForm} encType="multipart/form-data">
          <input type="file" name="file" />
        </form>
      </div>
      <div className="btn-group">
        <button type="button" className="btn btn-primary" onClick={submit}>Submit</button>
        <button type="button" className="btn btn-secondary" onClick={() => setActiveModule(null)}>Cancel</button>
      </div>
    </>
  );
};

MessageView2.propTypes = {
  setStep: PropTypes.func.isRequired
};

const MessageView3 = () => {
  return (
    <div>
      Basemap has been set.
    </div>
  );
};

export class SetBasemapModule extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      step: props.step
    };
  }

  setStep (value) {
    this.setState({...this.state, step: value});
  }

  render() {
    return [
      <MessageView1 key="0" setStep={this.setStep.bind(this)} />,
      <MessageView2 key="1" setStep={this.setStep.bind(this)} />,
      <MessageView3 key="2" />
    ][this.state.step] || null;
  }
}

SetBasemapModule.propTypes = {
  step: PropTypes.number.isRequired
};
