//
//  DDDecoder.h
//  FFMPEGDemo
//
//  Created by yuanyongguo on 16/7/13.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"
#import "swscale.h"
#import "swresample.h"
#import "DDPacket.h"
#import "DDPicture.h"



@interface DDDecoder : NSObject{
   
@public
    AVFormatContext * formatContext;
    AVStream * vedioStream;
    AVStream * audioStream;
    AVStream * subLineStream;
    int vedioIndex;
    int audioIndex;
    int subLineIndex;
    AVCodecContext *vedioCodecContext;
    AVCodecContext *audioCodecContext;
    AVCodec *vedioCodec;
    AVCodec *audioCodec;
}


@property(nonatomic,strong) NSMutableArray *vedioFrameArray;
@property(nonatomic,strong) NSMutableArray *audioFrameArray;

@property(nonatomic,assign) BOOL isEND;
@property(nonatomic,assign) BOOL isEnoughBuffer;//缓存是否充足
@property(nonatomic,assign) NSTimeInterval  startPlayBufferInterval;
@property(nonatomic,assign) NSTimeInterval pauseDecodeBufferInterval;

@property(nonatomic,assign) NSTimeInterval  totalTimeInterval;//总时长
@property(nonatomic,assign) NSTimeInterval  currentVedioInterval;//当前视频播放进度
@property(nonatomic,assign) NSTimeInterval  currentAudioInterval;//当前音频播放进度
@property(nonatomic,assign) NSTimeInterval  currentVedioCacheInterval;//视频缓冲时间
@property(nonatomic,assign) NSTimeInterval  currentAudioCahcheInterval;//音频的缓冲时间

@property(nonatomic,copy) void(^updateVedioInterval)(NSTimeInterval vedioInterval);
@property(nonatomic,copy) void(^updateCacheVedioInterval)(NSTimeInterval cacheVedioInterval);
@property(nonatomic,copy) void(^updateAudioInterval)(NSTimeInterval audioInterval);
@property(nonatomic,copy) void(^updateCacheAudioInterval)(NSTimeInterval cacheAudioInterval);


-(BOOL) loadFilePath:(NSString *) filePath ;

-(void) play ;
-(void) pause;
-(void) stop;
-(void) clearCacheInfo;
-(BOOL) seekWithTime:(NSTimeInterval) seekInterval;
-(void) readFrameWithDuation:(CGFloat) readDuration;

-(DDPacket *) popDDPacketWithVedioQueue;
-(DDPacket *) ftechDDPacketWithAudioQueue;
-(void)  removeDDPacketWithAudioQueue;

-(DDPicture *) convertDDPacketToImage:(DDPacket *) dFrame;

@end
