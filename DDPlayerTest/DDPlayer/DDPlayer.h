//
//  DDViewPlayer.h
//  FFMPEGDemo
//
//  Created by yuanyongguo on 16/7/19.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDDecoder.h"
#import "DDAudioManager.h"


typedef  NS_ENUM(NSInteger,Status) {
    StatusNormal,  //未播放
    StatusPlaying, //播放中
    StatusCacheNoEnough, //播放中缓存不足
    StatusSeek,//跳转中
    StatusPause,   //暂停
    StatusStop,    //停止
    StatusEnd      //结束
};

@interface DDPlayer : UIImageView

@property(nonatomic,strong) DDAudioManager *audioManager;
@property(nonatomic,assign) Status  status;//状态
@property(nonatomic,strong) DDDecoder *decoder;
@property(nonatomic,assign) NSTimeInterval  currentVedioInterval;//当前视频播放进度
@property(nonatomic,assign) NSTimeInterval  currentAudioInterval;//当前音频播放进度



-(BOOL) play;
-(void) pause;
-(void) stop;
-(BOOL) seekWithTime:(NSTimeInterval) seekInterval;
-(BOOL) loadFilePath:(NSString *) filePath;

@end
