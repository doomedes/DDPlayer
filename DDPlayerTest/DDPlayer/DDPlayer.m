//
//  DDViewPlayer.m
//  FFMPEGDemo
//
//  Created by yuanyongguo on 16/7/19.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import "DDPlayer.h"

@interface DDPlayer ()

@property(nonatomic,copy) NSString * fileUrl;

@end

@implementation DDPlayer {

    dispatch_queue_t dispatchSerial;
    BOOL isEnoughBuffer;//缓存是否充足
    NSTimeInterval startInterval; //开始播放的时间（系统时间）
    CGFloat startPosition;//开始播放的时间（视频时间）
}


-(DDDecoder *) decoder {
    if(!_decoder) {
        _decoder=[DDDecoder new];
    }
    return _decoder;
}

-(DDAudioManager *)audioManager {
    if(!_audioManager){
        _audioManager=[[DDAudioManager alloc]init];
    }
    return _audioManager;
}

-(BOOL) loadFilePath:(NSString *) filePath {
    
    self.fileUrl=filePath;
    if([self.decoder loadFilePath:filePath]){
        [self.audioManager loadInfoWithAVFormatContext:self.decoder->audioCodecContext streamIndex:self.decoder->audioIndex];
        __weak typeof(self) weakSelf=self;
        self.audioManager.requestNextFrame=^(){
            return [weakSelf.decoder ftechDDPacketWithAudioQueue];
        };
        self.audioManager.removeCurrentFrame=^(){
            [weakSelf.decoder removeDDPacketWithAudioQueue];
        };
        return YES;
    }
    return NO;
}


-(BOOL) play {
    
    if(self.status==StatusPlaying){
        return YES;
    }
    if(!self.fileUrl){
        return NO;
    }else{
        if(self.status==StatusNormal||self.status==StatusStop||self.status==StatusEnd){
            //从新播放
            dispatchSerial=dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
            
            [self.decoder readFrameWithDuation:0.4];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self showVedioAndAudio];
                [self.decoder play];
                [self.audioManager startAudioQueueWithFFMPeg];
            });
            self.status=StatusPlaying;

        }else if(self.status==StatusPause||self.status==StatusCacheNoEnough){
         self.status=StatusPlaying;
        }
        
    }
    return YES;
}

-(void) pause {
    self.status=StatusPause;
    [self.decoder pause];
    startInterval=0;
}

-(void) stop {
    self.status=StatusStop;
    [self.decoder stop];
    startInterval=0;
}

-(BOOL) seekWithTime:(NSTimeInterval) seekInterval {
    dispatchSerial=nil;
    dispatchSerial=dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    self.status=StatusSeek;
    if(![self.decoder seekWithTime:seekInterval]){
        return NO;
    }
    [self.audioManager seekQueueBufferWithFFMPeg];
    startInterval=0;
    return YES;
}

-(void) showVedioAndAudio {
    __block  NSTimeInterval timeDifference=0.01;//时间差(无时间差时每隔0.01解码数据)
    if(!isEnoughBuffer&&self.decoder.isEnoughBuffer){
           isEnoughBuffer=YES;
           self.status=StatusPlaying;
       }else{
           isEnoughBuffer=NO;
       }
     //播放操作
    if(isEnoughBuffer&&self.status==StatusPlaying){
        
        [self.audioManager addQueueBufferWithFFMPeg];
        
        DDPacket *dPacket=[self.decoder popDDPacketWithVedioQueue];
        if(dPacket){
            DDPicture *dPicture=[self.decoder convertDDPacketToImage:dPacket];
            self.image=dPicture.image;
            //计算下一帧视频和当前帧的时间差
            NSTimeInterval nowInterval=[NSDate timeIntervalSinceReferenceDate];
          
            if(startInterval==0){
                startInterval=nowInterval;
                startPosition=dPacket.best_effort_timestamp;
            }
            timeDifference= (dPacket.best_effort_timestamp-startPosition)-(nowInterval-startInterval);
            timeDifference=MAX(dPacket.pkt_duration+timeDifference, 0);
            NSLog(@"vedio=====%f===%f====%f====%lu====%lu",timeDifference,dPicture.pts,dPicture.pkt_duration,(unsigned long)self.decoder.vedioFrameArray.count,(unsigned long)self.decoder.audioFrameArray.count);
           
        }
    }
    
   //播放状态则读取数据解码
    if(self.status==StatusPlaying||self.status==StatusCacheNoEnough||self.status==StatusSeek){
            if(!self.decoder.isEnoughBuffer){
                if(self.decoder.isEND){
                    //停止播放(结束)
                    [self stop];
                     self.status=StatusEnd;
                    return;
                }else{
                    //缓存不足
                    isEnoughBuffer=NO;
                    self.status=StatusCacheNoEnough;
                    startInterval=0;//重新计时开始的系统时间
//                    NSLog(@"cache..........");
                }
            }
        //根据时间差显示下一帧数据
        dispatch_time_t time=dispatch_time(DISPATCH_TIME_NOW,timeDifference*NSEC_PER_SEC);
        dispatch_after(time, dispatch_get_main_queue(), ^{
            [self showVedioAndAudio];
        });
    }else{
        NSLog(@"break");
    }
    
}

@end
