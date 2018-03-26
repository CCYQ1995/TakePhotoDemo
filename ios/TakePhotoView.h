//
//  TakePhotoView.h
//  W00_PRO
//
//  Created by CCYQ on 2018/3/22.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TakePhotoView : UIView

typedef void(^onTouchBackBlock)(NSDictionary *dicBlock);

@property (nonatomic, copy) onTouchBackBlock onTouchBackBlock;

- (instancetype)init;

- (void)camareStartRunning;

- (void)camareStopRunning;


@end
