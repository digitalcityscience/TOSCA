import React from 'react';
import PropTypes from 'prop-types';

import { GlobalContext } from '../../store/global';

const MessageView1 = ({ setStep }) => {
  const { setActiveModule, drawings, WPS } = React.useContext(GlobalContext);
  const geojson = drawings.toGeoJSON();

  if (!geojson || geojson.features.length === 0) {
    return null;
  }

  const submit = async () => {
    try {
      await WPS.Execute('set_selection', [], [{
        identifier: 'selection',
        data: JSON.stringify(geojson)
      }]);
      setStep(1);
    } catch (err) {
      console.error(err.message);
    }
  };

  return (
    <>
      <div>
        A ‘selection’ is a selected part of the basemap area. Calculations will only be performed for that selection. Use the polygon tool to set the selection. When you have finished drawing, click ‘Save’ to set your drawing as selection.
        <br/>
        <small>The selection area has to overlap with the basemap boundary.</small>
      </div>
      <div className="btn-group">
        <button type="button" className="btn btn-primary" onClick={submit}>Save</button>
        <button type="button" className="btn btn-secondary" onClick={() => setActiveModule(null)}>Cancel</button>
      </div>
    </>
  );
};

MessageView1.propTypes = {
  setStep: PropTypes.func.isRequired
};

const MessageView2 = () => {
  return (
    <div>
      Selection has been set.
    </div>
  );
};

export class SetSelectionModule extends React.Component {
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
      <MessageView2 key="1" />
    ][this.state.step] || null;
  }
}

SetSelectionModule.propTypes = {
  step: PropTypes.number.isRequired
};
