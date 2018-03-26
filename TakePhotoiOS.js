import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  requireNativeComponent,
  NativeModules,
  Dimensions,
  NavigatorIOS
} from 'react-native';

const RNTakePhoto = requireNativeComponent('TakePhoto', TakePhotoiOS);
const TakePhotoManager = NativeModules.TakePhotoManager;


class TakePhotoiOS extends Component {
  constructor(props) {
    super(props);
  }
  
  componentDidMount() {
    /*
    * 这里采用延迟250毫秒后调用相机开启的方法是，因为在
    * 原生层中，TakePhotoView 被创建之后，才能调用 相机开启
    * 也等同于要 RNTakePhoto 被创建之后，才能调用
    */
    this.timeOutReFresh = setTimeout(() => {
      TakePhotoManager.camareStartRunning();
    }, 250);
  }
  
  componentWillUnmount() {
    TakePhotoManager.camareStopRunning();
  }
  
  render() {
    return (
      <RNTakePhoto
        style={styles.container}
        onTouchBackBlock={(event) => {
          console.log(event.nativeEvent);
          const eventMessage = event.nativeEvent;
          console.log(eventMessage.message);
          if (eventMessage.message === 'goBack') {
            // Actions.pop();
            this.props.navigator.pop();
          } else if (eventMessage.message === 'NoPermission') {
            TakePhotoManager.gotoOpenPermission({
              title: '提示',
              message: '没有权限，是否去开启权限',
              sureText: '确定',
              cancelText: '取消',
            });
          }
        }}
      />
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'transparent',
  },
  
  takePhotoView: {
    flex: 1,
    backgroundColor: 'transparent',
  }
  
});

module.exports = TakePhotoiOS;
