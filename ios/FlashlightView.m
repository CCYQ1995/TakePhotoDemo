//
//  FlashlightView.m
//  W00_PRO
//
//  Created by CCYQ on 2018/3/22.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "FlashlightView.h"

#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
#define functionViewHeight 54
#define functionBtnWidth 44
#define functionBtnHeight 44
#define firstBtnSpacing 12

@interface FlashlightView ()

/**
 *  设备信息的集合
 */
@property (nonatomic, strong) NSMutableArray *marrDeviceInfo;

@property (nonatomic, strong) NSArray *arrFunction;

@end

@implementation FlashlightView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)init {
  self = [super init];
  if (self) {
    //        self.userInteractionEnabled = YES;
    //        [self createView];
    
    UIButton *btnTouch = [[UIButton alloc] init];
    btnTouch.frame = CGRectMake(24, 64, 100, 30);
    [btnTouch setTitle:@"什么鬼" forState:0];
    [btnTouch setTitleColor:[UIColor purpleColor] forState:0];
    [btnTouch setBackgroundColor:[UIColor orangeColor]];
    [btnTouch addTarget:self action:@selector(btnTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btnTouch];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self createViewWithFrame:frame];
  }
  return self;
}

- (void)btnTouch:(UIButton *)sender {
  NSLog(@"什么鬼");
}

- (void)createViewWithFrame:(CGRect)frame {
  _arrFunction = @[
                   @{@"name":@"", @"imageName":@"flashlight"},
                   @{@"name":@"自动", @"imageName":@""},
                   @{@"name":@"打开", @"imageName":@""},
                   @{@"name":@"关闭", @"imageName":@""},
                   ];
  
  UIView *functionView = [[UIView alloc] init];
  functionView.userInteractionEnabled = YES;
  functionView.frame = frame;
  functionView.backgroundColor = [UIColor clearColor];
  [self addSubview:functionView];
  
  int i = 0;
  for (NSDictionary *dicFunction in _arrFunction) {
    UIButton *btnFunction = [UIButton buttonWithType:UIButtonTypeCustom];
    btnFunction.tag = i;
    if ([self isValid:dicFunction[@"name"]]) {
      [btnFunction setTitle:dicFunction[@"name"] forState:0];
    }else if ([self isValid:dicFunction[@"imageName"]]) {
      [btnFunction setImage:[UIImage imageNamed:dicFunction[@"imageName"]] forState:0];
    }
    [btnFunction addTarget:self action:@selector(touchFunction:) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat spacing = (frame.size.width - 24 - functionBtnWidth * _arrFunction.count) / _arrFunction.count;
    CGRect btnFrame = CGRectMake(0, 0, functionBtnWidth, functionBtnHeight);
    CGFloat heightSpacing = (functionViewHeight - functionBtnHeight) / 2;
    
    if (i == 0) {
      btnFrame = CGRectMake(firstBtnSpacing, heightSpacing, functionBtnWidth, functionBtnHeight);
    }else {
      CGFloat xSpacing = firstBtnSpacing + (functionBtnWidth + spacing) * i;
      btnFrame = CGRectMake(xSpacing, heightSpacing, functionBtnWidth, functionBtnHeight);
    }
    btnFunction.frame = btnFrame;
    [functionView addSubview:btnFunction];
    i++;
  }
  
}

- (void)touchFunction:(UIButton *)sender {
  if ([self isValid:sender.titleLabel.text]) {
    self.touchBlock(@{@"name": sender.titleLabel.text});
  }else{
    self.touchBlock(_arrFunction[sender.tag]);
  }
  
}

/**
 *  检测字符串是否为空
 *
 *  @param str 目标字符串
 *
 *  @return 布尔值
 */
- (BOOL)isValid:(NSString *)str{
  
  if (!(str && [str isKindOfClass:[NSString class]] && str.length>0)) {
    return NO;
  }
  if (str && ![str isKindOfClass:[NSNull class]]) {
    
    if (str.length>0) {
      return YES;
    }else{
      return NO;
    }
  }else{
    return NO;
  }
}

@end
