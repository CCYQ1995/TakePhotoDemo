import React, { Component } from 'react';
import { AppRegistry, NavigatorIOS } from 'react-native';
import App from './App';

class NV extends Component {
  render() {
    return (
      <NavigatorIOS
        style={{ flex: 1 }}
        initialRoute={{
          component: App,
          title: '首页',
          passProps: {},
        }}
        navigationBarHidden={true}
      />
    );
  }
}

AppRegistry.registerComponent('TakePhotoDemo', () => NV);
