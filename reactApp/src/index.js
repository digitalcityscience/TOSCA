import React from 'react';
import ReactDOM from 'react-dom';
import { Root } from 'components';
import 'styles/style.css';
import { GlobalContextProvider } from './store/global';
import { AlertContextProvider } from './store/alert';
import { LoadingContextProvider } from './store/loading';

import 'regenerator-runtime/runtime';

const App = () => {
  return (
    <GlobalContextProvider>
      <AlertContextProvider>
        <LoadingContextProvider>
          <Root />
        </LoadingContextProvider>
      </AlertContextProvider>
    </GlobalContextProvider>
  );
};

ReactDOM.render(<App />, document.getElementById('app'));
