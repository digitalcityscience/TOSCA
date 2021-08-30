import React from 'react';
import { useAlert } from '../../store/alert';

import './styles/style.css';

export const AlertContainer = () => {
  const { alerts, removeAlert } = useAlert();

  return (alerts && alerts.length > 0 &&
    <div className="alert-container">
      {alerts.map((alert) =>
        (
          <div className="alert alert-danger" role="alert" key={alert.id}>
            <span>{alert.message}</span>
            <button className="btn btn-light" data-dismiss="alert" onClick={() => removeAlert(alert.id)}>×</button>
          </div>
        )
      )}
    </div>
  );
};
