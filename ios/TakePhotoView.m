//
//  TakePhotoView.m
//  W00_PRO
//
//  Created by CCYQ on 2018/3/22.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "TakePhotoView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Photos/PHPhotoLibrary.h>

#import "FlashlightView.h"

#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
#define kDevice_Is_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)


typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface TakePhotoView ()

//负责输入和输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureSession *captureSession;

//负责从AVCaptureDevice获得输入数据
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;

//照片输出流
@property (nonatomic, strong) AVCaptureStillImageOutput *captureStillImageOutput;

//相机拍摄预览图层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

// 闪光灯功能视图
@property (nonatomic, strong) UIView *flashlightView;

// 闪光灯按钮
@property (nonatomic, strong) UIButton *btnFlashlight;

// 闪光灯状态视图
@property (nonatomic, strong) FlashlightView *flashlightStateView;

//功能视图
@property (nonatomic, strong) UIView *functionView;

@property (nonatomic, strong) UIButton *btnTakePhoto;

// 缩略图
@property (nonatomic, strong) UIImageView *ivPhoto;

@end

@implementation TakePhotoView

- (instancetype)init {
  self = [super init];
  if (self) {
    [self createCameraView];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    //重点方法
    [session setCategory:AVAudioSessionCategoryAmbient error:nil];
    [session setActive:YES error:nil];
    
    NSError *error;
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    
    //注，ios9上不加这一句会无效
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    // 设置音量控制视图消失
    AVAudioSession *audio = [AVAudioSession sharedInstance];
    [audio setActive:YES error:nil];
    MPVolumeView *volumeView = [[MPVolumeView alloc]initWithFrame:CGRectMake(-20, -20, 10, 10)];
    volumeView.hidden = NO;
    [self addSubview:volumeView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
  }
  return self;
}

//系统声音改变
-(void)volumeChanged:(NSNotification *)notification{
  [self btnTakePhoto: _btnTakePhoto];
}

// 相机开始工作
- (void)camareStartRunning{
  [self.captureSession startRunning];
}

// 相机停止工作
- (void)camareStopRunning {
  [self.captureSession stopRunning];
}

- (void)createCameraView {
  // 初始化
  _captureSession = [[AVCaptureSession alloc] init];
  //设置相机的分辨率
  if ([_captureSession canSetSessionPreset: AVCaptureSessionPreset1920x1080]) {
    _captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
  }
  
  AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
  if (!captureDevice) {
    NSLog(@"获取摄像头出错");
    return;
  }
  
  NSError *error = nil;
  //根据输入设备初始化设备输入对象，用于获得输入数据
  _captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
  if (error) {
    NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
    return;
  }
  
  // 初始化设备输出对象，用于获得输出数据
  _captureStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
  //输出设置，设置为输出 JPEG
  if (@available(iOS 11.0, *)) {
    [_captureStillImageOutput setOutputSettings:@{AVVideoCodecKey: AVVideoCodecTypeJPEG}];
  } else {
    // Fallback on earlier versions
    [_captureStillImageOutput setOutputSettings:@{AVVideoCodecKey: AVVideoCodecJPEG}];
  }
  
  //将输入对象添加到会话层中
  if ([_captureSession canAddInput:_captureDeviceInput]) {
    [_captureSession addInput:_captureDeviceInput];
  }
  
  //将输出对象添加到会话层中
  if ([_captureSession canAddOutput:_captureStillImageOutput]) {
    [_captureSession addOutput:_captureStillImageOutput];
  }
  
  //创建预览图层
  _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
  CALayer *layer = self.layer;
  layer.masksToBounds = YES;
  _captureVideoPreviewLayer.frame = CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT);
  _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
  [layer addSublayer:_captureVideoPreviewLayer];
  
  // 设置闪光灯为自动
  [self setFlashMode:AVCaptureFlashModeAuto];
  
  // 增加闪光灯、拍照按钮等
  [self createLightView:layer];
  [self createFunctionView:layer];
  // 增加手势
  [self addGenstureRecognizer];
  // 增加监听
  [self addNotificationToCaptureDevice:captureDevice];
}

- (void)createLightView:(CALayer *)layer {
  _flashlightView = [[UIView alloc] init];
  _flashlightView.backgroundColor = [UIColor clearColor];
  _flashlightView.frame = CGRectMake(0, kDevice_Is_iPhoneX ? 40 : 20, SCREENWIDTH, 54);
  [self addSubview:_flashlightView];
  
  // 闪光灯按钮
  _btnFlashlight = [UIButton buttonWithType:UIButtonTypeCustom];
  _btnFlashlight.frame = CGRectMake(12, 5, 44, 44);
  [_btnFlashlight setImage:[UIImage imageNamed:@"flashlight"] forState:0];
  [_btnFlashlight addTarget:self action:@selector(showFlashlight:) forControlEvents:UIControlEventTouchUpInside];
  [_flashlightView addSubview:_btnFlashlight];
  
  _flashlightStateView = [[FlashlightView alloc] initWithFrame:CGRectMake(0, 0, SCREENWIDTH - 56, 54)];
  _flashlightStateView.hidden = YES;
  __weak typeof(self) wSelf = self;
  _flashlightStateView.touchBlock = ^(NSDictionary *touchDic) {
    if ([touchDic[@"name"] isEqualToString:@"自动"]) {
      [wSelf setFlashMode:AVCaptureFlashModeAuto];
      wSelf.flashlightStateView.hidden = YES;
      [wSelf.btnFlashlight setImage:[UIImage imageNamed:@"flashlight"] forState:0];
    }else if ([touchDic[@"name"] isEqualToString:@"打开"]) {
      [wSelf setFlashMode:AVCaptureFlashModeOn];
      wSelf.flashlightStateView.hidden = YES;
      [wSelf.btnFlashlight setImage:[UIImage imageNamed:@"flashlight_y"] forState:0];
    }else if ([touchDic[@"name"] isEqualToString:@"关闭"]) {
      [wSelf setFlashMode:AVCaptureFlashModeOff];
      wSelf.flashlightStateView.hidden = YES;
      [wSelf.btnFlashlight setImage:[UIImage imageNamed:@"flashlight_no"] forState:0];
    }else {
      wSelf.flashlightStateView.hidden = YES;
    }
  };
  
  UIButton *btnClose = [UIButton buttonWithType:UIButtonTypeCustom];
  [btnClose setImage:[UIImage imageNamed:@"close"] forState:0];
  [btnClose addTarget:self action:@selector(btnCloseAction:) forControlEvents:UIControlEventTouchUpInside];
  btnClose.frame = CGRectMake(SCREENWIDTH - 56, 5, 44, 44);
  [_flashlightView addSubview:btnClose];
  
  [_flashlightView addSubview:_flashlightStateView];
}

- (void)createFunctionView:(CALayer *)layer {
  _functionView = [[UIView alloc] init];
  _functionView.backgroundColor = [UIColor clearColor];
  
  _functionView.frame = CGRectMake(0, kDevice_Is_iPhoneX ? SCREENHEIGHT - 120 : SCREENHEIGHT - 100, SCREENWIDTH, kDevice_Is_iPhoneX ? 120 : 100);
  [layer addSublayer:_functionView.layer];
  
  // 拍照
  _btnTakePhoto = [UIButton buttonWithType:UIButtonTypeCustom];
  [_btnTakePhoto setImage:[UIImage imageNamed:@"TakingPictures"] forState:0];
  [_btnTakePhoto addTarget:self action:@selector(btnTakePhoto:) forControlEvents:UIControlEventTouchUpInside];
  _btnTakePhoto.frame = CGRectMake((SCREENWIDTH - 80) / 2, 10, 80, 80);
  [self roundView:_btnTakePhoto radius:40];
  [_functionView addSubview:_btnTakePhoto];
  
  // 切换摄像头
  UIButton *btnChangeCamera = [UIButton buttonWithType:UIButtonTypeCustom];
  [btnChangeCamera setImage:[UIImage imageNamed:@"reverse"] forState:0];
  [btnChangeCamera addTarget:self action:@selector(changeCameraAction:) forControlEvents:UIControlEventTouchUpInside];
  btnChangeCamera.frame = CGRectMake(SCREENWIDTH - 60 - 12, 20, 60, 60);
  [_functionView addSubview:btnChangeCamera];
  
  //
  _ivPhoto = [[UIImageView alloc] init];
  _ivPhoto.frame = CGRectMake(12, 20, 60, 60);
  [self roundView:_ivPhoto radius:5];
  [_ivPhoto setContentMode:UIViewContentModeScaleAspectFill];
  _ivPhoto.clipsToBounds = YES;
  [_functionView addSubview:_ivPhoto];
  
  if (SCREENHEIGHT > 736) {
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 100, SCREENWIDTH, 20)];
    bottomView.backgroundColor = [UIColor clearColor];
    [_functionView addSubview:bottomView];
  }
  
}

/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
  NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  for (AVCaptureDevice *camera in cameras) {
    if ([camera position] == position) {
      return camera;
    }
  }
  return nil;
}

/**
 *  改变设备属性的统一操作方法
 *
 *  @param propertyChange 属性改变操作
 */
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
  AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
  NSError *error;
  //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
  if ([captureDevice lockForConfiguration:&error]) {
    propertyChange(captureDevice);
    [captureDevice unlockForConfiguration];
  }else{
    NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
  }
}

/**
 *  设置闪光灯模式
 *
 *  @param flashMode 闪光灯模式
 */
-(void)setFlashMode:(AVCaptureFlashMode )flashMode{
  [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
    if ([captureDevice isFlashModeSupported:flashMode]) {
      [captureDevice setFlashMode:flashMode];
    }
  }];
}

/**
 *  设置聚焦模式
 *
 *  @param focusMode 聚焦模式
 */
-(void)setFocusMode:(AVCaptureFocusMode )focusMode{
  [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
    if ([captureDevice isFocusModeSupported:focusMode]) {
      [captureDevice setFocusMode:focusMode];
    }
  }];
}
/**
 *  设置曝光模式
 *
 *  @param exposureMode 曝光模式
 */
-(void)setExposureMode:(AVCaptureExposureMode)exposureMode{
  [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
    if ([captureDevice isExposureModeSupported:exposureMode]) {
      [captureDevice setExposureMode:exposureMode];
    }
  }];
}

/**
 *  设置聚焦点
 *
 *  @param point 聚焦点
 */
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
  [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
    if ([captureDevice isFocusModeSupported:focusMode]) {
      [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    if ([captureDevice isFocusPointOfInterestSupported]) {
      [captureDevice setFocusPointOfInterest:point];
    }
    if ([captureDevice isExposureModeSupported:exposureMode]) {
      [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
    }
    if ([captureDevice isExposurePointOfInterestSupported]) {
      [captureDevice setExposurePointOfInterest:point];
    }
  }];
}

/**
 *  添加点按手势，点按时聚焦
 */
-(void)addGenstureRecognizer {
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
  [self addGestureRecognizer:tapGesture];
}
-(void)tapScreen:(UITapGestureRecognizer *)tapGesture {
  NSLog(@"tapGesture ------ ");
  CGPoint point = [tapGesture locationInView:self];
  //将UI坐标转化为摄像头坐标
  CGPoint cameraPoint = [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
  //    [self setFocusCursorWithPoint:point];
  [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

//
- (void)showFlashlight:(UIButton *)sender {
  _flashlightStateView.hidden = !_flashlightStateView.hidden;
}

//
- (void)btnTakePhoto:(UIButton *)sender {
  NSLog(@"开始拍照");
  [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
      _onTouchBackBlock(@{@"message": @"NoPermission"});
    } else {
      //根据设备输出获得连接
      AVCaptureConnection *captureConnection = [self.captureStillImageOutput connectionWithMediaType:AVMediaTypeVideo];
      //根据连接取得设备输出的数据
      [self.captureStillImageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer) {
          NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
          UIImage *image = [UIImage imageWithData:imageData];
          _ivPhoto.image = image;
          _ivPhoto.layer.borderWidth = 1;
          _ivPhoto.layer.borderColor = [UIColor whiteColor].CGColor;
          UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        }
      }];
    }
  }];
}

// 切换摄像头
- (void)changeCameraAction:(UIButton *)sender {
  AVCaptureDevice *currentDevice = [self.captureDeviceInput device];
  AVCaptureDevicePosition currentPosition = [currentDevice position];
  [self removeNotificationFromCaptureDevice:currentDevice];
  AVCaptureDevice *toChangeDevice;
  AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;
  if (currentPosition == AVCaptureDevicePositionUnspecified||currentPosition == AVCaptureDevicePositionFront) {
    toChangePosition = AVCaptureDevicePositionBack;
  }
  toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];
  [self addNotificationToCaptureDevice:toChangeDevice];
  //获得要调整的设备输入对象
  AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
  
  //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
  [self.captureSession beginConfiguration];
  //移除原有输入对象
  [self.captureSession removeInput:self.captureDeviceInput];
  //添加新的输入对象
  if ([self.captureSession canAddInput:toChangeDeviceInput]) {
    [self.captureSession addInput:toChangeDeviceInput];
    self.captureDeviceInput = toChangeDeviceInput;
  }
  //提交会话配置
  [self.captureSession commitConfiguration];
}

- (void)btnCloseAction:(UIButton *)sender {
  [self removeNotification];
  [self camareStartRunning];
  _onTouchBackBlock(@{@"message": @"goBack"});
}

#pragma mark - 通知
/**
 *  移除所有通知
 */
- (void)removeNotification {
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter removeObserver:self];
}

- (void)addNotificationToCaptureSession:(AVCaptureSession *)captureSession {
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  //会话出错
  [notificationCenter addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
}

/**
 *  给输入设备添加通知
 */
- (void)addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice {
  //注意添加区域改变捕获通知必须首先设置设备允许捕获
  [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
    captureDevice.subjectAreaChangeMonitoringEnabled=YES;
  }];
  NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
  //捕获区域发生改变
  [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}

- (void)removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice {
  NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
  [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}

/**
 *  设备连接成功
 *
 *  @param notification 通知对象
 */
- (void)deviceConnected:(NSNotification *)notification {
  NSLog(@"设备已连接...");
}
/**
 *  设备连接断开
 *
 *  @param notification 通知对象
 */
- (void)deviceDisconnected:(NSNotification *)notification {
  NSLog(@"设备已断开.");
}
/**
 *  捕获区域改变
 *
 *  @param notification 通知对象
 */
- (void)areaChange:(NSNotification *)notification {
  NSLog(@"捕获区域改变...");
}

/**
 *  会话出错
 *
 *  @param notification 通知对象
 */
- (void)sessionRuntimeError:(NSNotification *)notification {
  NSLog(@"会话发生错误.");
}

- (void)roundView:(UIView *)view radius:(CGFloat)cornerRadius {
  view.layer.cornerRadius = cornerRadius;
  view.layer.masksToBounds = YES;
  view.layer.shouldRasterize = YES;
  view.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)dealloc {
  [self removeNotification];
}

@end
