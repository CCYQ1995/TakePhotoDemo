//
//  TakePhotoManager.m
//  W00_PRO
//
//  Created by CCYQ on 2018/3/22.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "TakePhotoManager.h"
#import "TakePhotoView.h"
#import <Photos/PHPhotoLibrary.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>

@interface TakePhotoManager()

@property (nonatomic, strong) TakePhotoView *takePhotoView;

// 点击返回的block
@property (nonatomic, copy) RCTBubblingEventBlock onTouchBackBlock;

//@property (strong, nonatomic) RCTPromiseResolveBlock ocResolve;
//@property (strong, nonatomic) RCTPromiseRejectBlock ocReject;

@end

@implementation TakePhotoManager

// 标记宏（必要）
RCT_EXPORT_MODULE()

// 事件的导出
RCT_EXPORT_VIEW_PROPERTY(onTouchBackBlock, RCTBubblingEventBlock)

- (UIView *)view {
  _takePhotoView = [[TakePhotoView alloc] init];
  _takePhotoView.onTouchBackBlock = ^(NSDictionary *dicBlock) {
  };
  return _takePhotoView;
}

/**
 *  相机开始工作
 */
RCT_EXPORT_METHOD(camareStartRunning) {
  [_takePhotoView camareStartRunning];
}

/**
 *  相机停止工作
 */
RCT_EXPORT_METHOD(camareStopRunning) {
  [_takePhotoView camareStopRunning];
}


RCT_EXPORT_METHOD(sureUseCamare:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  //相机权限
  AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  //此应用程序没有被授权访问的照片数据。可能是家长控制权限
  //用户已经明确否认了这一照片数据的应用程序访问
  if (authStatus ==AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) {
    reject(@"error", @"No permission", nil);
  }else {
    resolve(@{@"name":@"success"});
  }
}

RCT_EXPORT_METHOD(gotoOpenPermission:(NSDictionary *)dicText) {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:dicText[@"title"] message:dicText[@"message"] preferredStyle:UIAlertControllerStyleAlert];
  // 确定
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:dicText[@"sureText"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    dispatch_async(dispatch_get_main_queue(), ^{
      if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
      }
    });
  }];
  
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:dicText[@"cancelText"] style:UIAlertActionStyleCancel handler:nil];
  
  [alert addAction:okAction];
  [alert addAction:cancelAction];
  // 弹出对话框
  [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:true completion:nil];
}

@end

