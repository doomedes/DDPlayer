//
//  DDAudioManager.h
//  FFMPEGDemo
//
//  Created by yuanyongguo on 16/7/1.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "DDPacket.h"
#import "avcodec.h"

typedef  DDPacket * (^NextFrame)();

@interface DDAudioManager : NSObject {

@public
   
}

@property(nonatomic,copy) NextFrame requestNextFrame;

@property(nonatomic,copy) void (^removeCurrentFrame)();

-(void) loadInfoWithAVFormatContext:(AVCodecContext *) avCodecContext streamIndex:(int ) streamIndex;//初始化audioQueue

-(void)  startAudioQueueWithFFMPeg ;//启动播放

-(void)  pausAudioQueueWithFFMPeg;//暂停audioQueue

-(void)  stopAudioQueueWithFFMPeg;//停止audioQueue

//-(void) addAudioPacketQueueWithPacket:(AVPacket) packet;//添加数据包到数组中缓存下来以便添加到audioQueueBuffer中

-(void) addQueueBufferWithFFMPeg;//添加数据到audioQueueBuffer

-(void) seekQueueBufferWithFFMPeg;//跳转时间时


@end

