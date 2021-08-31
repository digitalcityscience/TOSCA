import React from 'react';
import { useLoading } from '../../store/loading';

import './styles/style.css';

export const LoadingContainer = () => {
  const { isLoading } = useLoading();

  return (isLoading &&
    <div className="loading-container">
      <div className="loading-text"></div>
      <div className="spinner spinner-border"></div>
    </div>
  );
};
