//
//  DDAudioManager.m
//  FFMPEGDemo
//
//  Created by yuanyongguo on 16/7/1.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import "DDAudioManager.h"

#define  NUM_BUFFERS 3


//audioQueue属性监控
void audioQueuePropertyListenerProc(void * __nullable inUserData,AudioQueueRef inAQ,AudioQueuePropertyID inID) {
    
    if(inID==kAudioQueueProperty_IsRunning){
        UInt32 isRuning;
        UInt32 inDataSize=sizeof(isRuning);
        OSStatus status= AudioQueueGetProperty(inAQ, inID, &isRuning, &inDataSize);
        if(status==noErr&&!isRuning){
            //播放停止了
        }
    }
    
}

//AudioQueueRef的回调函数
void audioQueueOutputCallbackWithFFMPeg(void * __nullable inUserData, AudioQueueRef inAQ,AudioQueueBufferRef inBuffer) {
    DDAudioManager * audioManager=(__bridge DDAudioManager*)inUserData;
    if([audioManager respondsToSelector:NSSelectorFromString(@"addQueueBufferWithFFMPeg:")]){
        [audioManager performSelector:NSSelectorFromString(@"addQueueBufferWithFFMPeg:") withObject:(__bridge id)inBuffer];
    }
}

@interface DDAudioManager ()

@end

@implementation DDAudioManager {

    
    OSStatus status;
//    AudioFileID  audioFileId;
    AudioQueueRef audioQueue;
    AudioStreamBasicDescription  audioStreamBasicDes;
    AudioStreamPacketDescription  *audioStreamPacketDes;
    UInt32 oncePacketCount;//一次缓存数据的包数
    SInt64 startIndexPacket;//开始读取包的下标
    
    AudioQueueBufferRef freshAudioQueueBuffer;
    AudioQueueBufferRef currentAudioQueueBuffer;
    
    
    AVCodecContext * av_CodecContext;
//    int audioStatus;//0 未开始 1播放中  2暂停 3停止
    int isNewBuffer;// 0 没有新的缓存 1 当前是新缓存
    
    dispatch_queue_t dispatch_queue_serial;
    NSRecursiveLock * isNewBufferLock;
    NSRecursiveLock *rdLock;
    
}

#pragma mark- method


/**
 *  根据AVCodecContext创建audioQueue
 *
 *  @param avCodecContext <#avCodecContext description#>
 *  @param streamIndex    <#streamIndex description#>
 */
-(void) loadInfoWithAVFormatContext:(AVCodecContext *) avCodecContext streamIndex:(int ) streamIndex {
    dispatch_queue_serial=dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    rdLock=[[NSRecursiveLock alloc]init];
    av_CodecContext=avCodecContext;
    isNewBufferLock=[NSRecursiveLock new];
    
    audioStreamBasicDes.mFormatID=kAudioFormatLinearPCM;//音频数据的格式(mp3、pcm等)
    audioStreamBasicDes.mSampleRate=avCodecContext->sample_rate; //采样率
    if(audioStreamBasicDes.mSampleRate<1){
        audioStreamBasicDes.mSampleRate=32000;
    }
    audioStreamBasicDes.mFormatFlags=0;
    //设置不同音频格式的信息
    switch (avCodecContext->codec_id) {
        case CODEC_ID_MP3: {
            audioStreamBasicDes.mFormatID=kAudioFormatMPEGLayer3;
            break;
        }
        case CODEC_ID_AAC: {
            audioStreamBasicDes.mFormatID=kAudioFormatMPEG4AAC;
            audioStreamBasicDes.mSampleRate=avCodecContext->sample_rate;
            audioStreamBasicDes.mFormatFlags=kMPEG4Object_AAC_LC;
            audioStreamBasicDes.mChannelsPerFrame=2;//1:单声道；2:立体声
            audioStreamBasicDes.mBitsPerChannel=0;  //语音每采样点占用位数
            audioStreamBasicDes.mFramesPerPacket=1024;//包的帧数
            audioStreamBasicDes.mBytesPerFrame=0;//包的字节数
            break;
        }
        case CODEC_ID_AC3: {
            audioStreamBasicDes.mFormatID=kAudioFormatAC3;
            break;
        }
        case CODEC_ID_PCM_MULAW: {
            audioStreamBasicDes.mFormatID = kAudioFormatULaw;
            audioStreamBasicDes.mSampleRate = 8000.0;
            audioStreamBasicDes.mFormatFlags = 0;
            audioStreamBasicDes.mFramesPerPacket = 1;
            audioStreamBasicDes.mChannelsPerFrame = 1;
            audioStreamBasicDes.mBitsPerChannel = 8;
            audioStreamBasicDes.mBytesPerPacket = 1;
            audioStreamBasicDes.mBytesPerFrame = 1;
            break;
        }
        default: {
            audioStreamBasicDes.mFormatID = kAudioFormatAC3;
        }
    }
    
    
    status=AudioQueueNewOutput(&audioStreamBasicDes, audioQueueOutputCallbackWithFFMPeg, (__bridge  void*)self, nil, nil, 0, &audioQueue);
    if(status!=noErr){
        NSLog(@"AudioQueueNewOutput faild!");
    }
    
    //添加播放状态的监控
    status=AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, audioQueuePropertyListenerProc, (__bridge  void*)self);
    if(status!=noErr){
        NSLog(@"AudioQueueAddPropertyListener faild!");
    }
    
    //初始化缓存
    AudioQueueAllocateBufferWithPacketDescriptions(audioQueue,
                                                   audioStreamBasicDes.mSampleRate*3/8,
                                                   avCodecContext->sample_rate * 3 / (avCodecContext->frame_size + 1),
                                                   &freshAudioQueueBuffer);
}

/**
 *  启动audioQueue
 */
-(void)  startAudioQueueWithFFMPeg {
    @synchronized (self) {
        UInt32 isRuning;
        UInt32 inDataSize=sizeof(isRuning);
        status=AudioQueueGetProperty(audioQueue, kAudioQueueProperty_IsRunning, &isRuning, &inDataSize);
        if(status!=noErr){
            NSLog(@"get is running  error！");
        }else{
            if(!isRuning){
                AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1);
                status=AudioQueueStart(audioQueue, 0);
                [self addQueueBufferWithFFMPeg:freshAudioQueueBuffer];
            }
            
        }
    }
}


/**
 *  暂停audioQueue
 */
-(void)  pausAudioQueueWithFFMPeg {
    @synchronized (self) {
        UInt32 isRuning;
        UInt32 inDataSize=sizeof(isRuning);
        status=AudioQueueGetProperty(audioQueue, kAudioQueueProperty_IsRunning, &isRuning, &inDataSize);
        if(status!=noErr){
            NSLog(@"get is running  error！");
        }else{
            if(isRuning){
                status=AudioQueuePause(audioQueue);
            }
            
        }
    }
}

-(void) seekQueueBufferWithFFMPeg {
    
    AudioQueueReset(audioQueue);//如果设置播放进度时则清空队列里面的数据否则会出现音频不同步
}




/**
 *  停止audioQueue
 */
-(void)  stopAudioQueueWithFFMPeg {
    @synchronized (self) {
        UInt32 isRuning;
        UInt32 inDataSize=sizeof(isRuning);
        status=AudioQueueGetProperty(audioQueue, kAudioQueueProperty_IsRunning, &isRuning, &inDataSize);
        if(status!=noErr){
            NSLog(@"get is running  error！");
        }else{
            if(!isRuning){
                status=AudioQueueStop(audioQueue, YES);
            }
            
        }
    }
}

//向保存的缓存队列添加数据
-(void) addQueueBufferWithFFMPeg {
    if(currentAudioQueueBuffer){
        [self addQueueBufferWithFFMPeg:nil];
    }
}

-(void) addQueueBufferWithFFMPeg:(AudioQueueBufferRef ) inBuffer {
  dispatch_async(dispatch_queue_serial, ^{
      if(inBuffer){
          
          currentAudioQueueBuffer=inBuffer;
          currentAudioQueueBuffer->mAudioDataByteSize = 0;
          currentAudioQueueBuffer->mPacketDescriptionCount = 0;
          isNewBuffer=1;
      }
      if(!currentAudioQueueBuffer|| !isNewBuffer){
          return;
      }
   
      //有packet数据  &&  有效的包数 < 最大的包数
      while (currentAudioQueueBuffer->mPacketDescriptionCount < currentAudioQueueBuffer->mPacketDescriptionCapacity) {
          
          if(!self.requestNextFrame){
              return;
          }
          DDPacket *dPacket=self.requestNextFrame();
          if(dPacket==nil){
              return;
          }
          
          //缓冲区大小－有效的缓存区大小 >读取packet的大小
          if (currentAudioQueueBuffer->mAudioDataBytesCapacity - currentAudioQueueBuffer->mAudioDataByteSize >= dPacket.dataLength) {
              memcpy((uint8_t *)currentAudioQueueBuffer->mAudioData + currentAudioQueueBuffer->mAudioDataByteSize,dPacket.packetData.bytes, dPacket.dataLength);
              currentAudioQueueBuffer->mPacketDescriptions[currentAudioQueueBuffer->mPacketDescriptionCount].mStartOffset = currentAudioQueueBuffer->mAudioDataByteSize;
              //数据帧包的数量
              currentAudioQueueBuffer->mPacketDescriptions[currentAudioQueueBuffer->mPacketDescriptionCount].mDataByteSize =dPacket.dataLength;
              //数据帧包的字节大小
              currentAudioQueueBuffer->mPacketDescriptions[currentAudioQueueBuffer->mPacketDescriptionCount].mVariableFramesInPacket = av_CodecContext->frame_size;
              
              currentAudioQueueBuffer->mAudioDataByteSize += dPacket.dataLength;
              currentAudioQueueBuffer->mPacketDescriptionCount++;
              self.removeCurrentFrame();
              
          }else {
              break;
          }
      }
      
      if (currentAudioQueueBuffer->mPacketDescriptionCount > 0) {
          status = AudioQueueEnqueueBuffer(audioQueue, currentAudioQueueBuffer, 0, NULL);
          if (status != noErr) {
              NSLog(@"Could not enqueue buffer.");
          }else{
              isNewBuffer=0;
          }
      }else{
          NSLog(@"mPacketDescriptionCount  <=0");
      }
  });

    
}



@end


