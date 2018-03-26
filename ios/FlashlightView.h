//
//  FlashlightView.h
//  W00_PRO
//
//  Created by CCYQ on 2018/3/22.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlashlightView : UIView

typedef void(^TouchCallBackBlock)(NSDictionary *touchDic);

- (instancetype)init;

- (instancetype)initWithFrame:(CGRect)frame;

@property (nonatomic, copy) TouchCallBackBlock touchBlock;

@end
