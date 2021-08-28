import React from 'react';
import ReactDOM from 'react-dom';
import { Root } from 'components';
import 'styles/style.css';
import { GlobalContextProvider } from './store/global';
import 'regenerator-runtime/runtime';

const App = () => {
  return (
    <GlobalContextProvider>
      <Root />
    </GlobalContextProvider>
  );
};

ReactDOM.render(<App />, document.getElementById('app'));
