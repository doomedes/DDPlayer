//
//  DDPicture.h
//  FFMPEGDemo
//
//  Created by 袁永国 on 16/7/9.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface DDPicture : NSObject

@property(nonatomic,strong) UIImage *image;

@property(nonatomic,assign) CGFloat pts;

@property(nonatomic,assign) CGFloat pkt_duration; //播放时长（显示时长）



@end
