//
//  DDDecoder.m
//  FFMPEGDemo
//
//  Created by yuanyongguo on 16/7/13.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import "DDDecoder.h"


@interface DDDecoder()


@end

@implementation DDDecoder
{
    NSTimer *readTimer;
    NSThread *readThread;
    bool isPause;
    struct SwsContext *rgbConvert;
//    struct SwrContext * swrConvert;
    NSTimeInterval currentSeekInterval;
    
}


-(NSMutableArray *)vedioFrameArray {
    if(!_vedioFrameArray){
        _vedioFrameArray=[NSMutableArray new];
    }
    return _vedioFrameArray;
}

-(NSMutableArray *)audioFrameArray{
    if(!_audioFrameArray){
        _audioFrameArray=[NSMutableArray new];
    }
    return _audioFrameArray;
}

-(NSTimeInterval)startPlayBufferInterval{
    if(_startPlayBufferInterval<=0){
        _startPlayBufferInterval=2;
    }
    return _startPlayBufferInterval;
}

-(NSTimeInterval)pauseDecodeBufferInterval {
    if(_pauseDecodeBufferInterval<=self.startPlayBufferInterval){
        _pauseDecodeBufferInterval=4;
    }
    return _pauseDecodeBufferInterval;
}

-(BOOL) isEnoughBuffer {
    NSUInteger frameCount=self.vedioFrameArray.count+self.audioFrameArray.count;
//    NSLog(@"%lu===%f===%f",(unsigned long)frameCount,self.currentVedioCacheInterval,self.currentAudioCahcheInterval);
    //缓存充足判断: 1、缓存>可播放的缓存大小 2、还有未读完的数据可能不满足可播放缓存的大小但是数据已近读完
    if((frameCount>0&&self.currentVedioCacheInterval>self.startPlayBufferInterval&&self.currentAudioCahcheInterval>self.startPlayBufferInterval)
    ||(frameCount>0&&self.isEND)){
        _isEnoughBuffer=YES;
    }else{
        _isEnoughBuffer=NO;
    }
    return _isEnoughBuffer;
}

#pragma  mark method

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}


/**
 *  取出vedio数据队列里队首数据且移除
 *
 *  @return DDPacket
 */
-(DDPacket *) popDDPacketWithVedioQueue {
    DDPacket *dPacket;
    @synchronized (self) {
        if(self.vedioFrameArray.count>0){
            dPacket=self.vedioFrameArray[0];
            [self.vedioFrameArray removeObjectAtIndex:0];
            self.currentVedioInterval+=dPacket.pkt_duration;
            self.currentVedioCacheInterval-=dPacket.pkt_duration;//减少缓存时间
        }
    }
    if(self.updateCacheVedioInterval){
        self.updateCacheVedioInterval(self.currentVedioCacheInterval);
    }
    if(self.updateVedioInterval){
        self.updateVedioInterval(self.currentVedioInterval);
    }
    
    return dPacket;
}


/**
 *  取audio数据队列中的第一项但是不移除
 *
 *  @return DDPacket
 */
-(DDPacket *) ftechDDPacketWithAudioQueue {
    DDPacket *dPacket=nil;
    @synchronized (self) {
        if( self.audioFrameArray.count>0){
            dPacket=self.audioFrameArray[0];
        }
    }
    return dPacket;
}

/**
 *  移除audio数据队列中的第一项数据
 */
-(void) removeDDPacketWithAudioQueue {
    @synchronized (self) {
        if( self.audioFrameArray.count>0){
            DDPacket *dPacket=self.audioFrameArray[0];
            [self.audioFrameArray removeObjectAtIndex:0];
            self.currentAudioInterval+=dPacket.pkt_duration;
            self.currentAudioCahcheInterval-=dPacket.pkt_duration;
        }
    }
    if(self.updateAudioInterval){
        self.updateAudioInterval(self.currentAudioInterval);
    }
    if(self.updateCacheAudioInterval){
        self.updateCacheAudioInterval(self.currentAudioCahcheInterval);
    }
}

-(void) play {
    isPause=NO;
    readThread=[[NSThread alloc]initWithTarget:self selector:@selector(startReadWithChildThread) object:nil];
    [readThread start];
}

-(void) startReadWithChildThread {
    NSTimeInterval interval=1.0/av_q2d(vedioStream->r_frame_rate);
    readTimer=[[NSTimer alloc]initWithFireDate:[NSDate date] interval:interval target:self selector:@selector(repeatsReadFrame) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:readTimer forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] run];
}

-(void) repeatsReadFrame {
    if(!self.isEND&&!(self.currentVedioCacheInterval>self.pauseDecodeBufferInterval&&self.currentAudioCahcheInterval>self.pauseDecodeBufferInterval)){
        [self readFrameWithDuation:2.0/av_q2d(vedioStream->r_frame_rate)];
    }
}

-(void) pause {
    isPause=YES;
}

-(void) stop {
    [readTimer invalidate];
    [readThread cancel];
    [self clearCacheInfo];
    
    avcodec_close(vedioCodecContext);
    avcodec_close(audioCodecContext);
    avformat_close_input(&formatContext);
    
}

-(void) clearCacheInfo {
    //清空缓存的数据、记录
    [self.vedioFrameArray removeAllObjects];
    [self.audioFrameArray removeAllObjects];
    self.currentVedioCacheInterval=0;
    self.currentAudioCahcheInterval=0;
    self.currentVedioInterval=0;
    self.currentAudioInterval=0;
}

-(BOOL) loadFilePath:(NSString *) filePath {
    [self clearCacheInfo];
    const char *path=[filePath UTF8String];
    formatContext=NULL;
    av_register_all();
    int codeResult=avformat_open_input(&formatContext,path,NULL,NULL);
    if(codeResult==0){
       codeResult=avformat_find_stream_info(formatContext, NULL);
        if(codeResult>=0){
            BOOL openVedioResult=[self openVedioStream];
            BOOL openAudioResult=[self openAudioStream];
            if(!(openAudioResult&&openVedioResult)){
                return NO;
            }
            
//             av_dump_format(formatContext,0,path,NULL);//输出文件信息
        }else{
            NSLog(@"avformat_find_stream_info error!");
            return NO;
        }
    }else{
        NSLog(@"avformat_open_input error!");
        return NO;
    }
    return YES;
}

-(BOOL) openVedioStream  {
    for (int i=0; i<formatContext->nb_streams; i++) {
        AVStream *stream= formatContext->streams[i];
        if(stream->codec->codec_type==AVMEDIA_TYPE_VIDEO){
            vedioStream=stream;
            vedioCodecContext=vedioStream->codec;
            vedioIndex=i;
            break;
        }
    }
    if(vedioIndex>=0){
        vedioCodec= avcodec_find_decoder(vedioCodecContext->codec_id);
        int codeResult=avcodec_open2(vedioCodecContext, vedioCodec, NULL);
        if(codeResult==0){
            self.totalTimeInterval=av_q2d(vedioStream->time_base)*vedioStream->duration;
            int outW,outH;
            outW=vedioCodecContext->width;
            outH=vedioCodecContext->height;
            static int sws_flag=SWS_FAST_BILINEAR;
            rgbConvert=sws_getContext(vedioCodecContext->width, vedioCodecContext->height, vedioCodecContext->pix_fmt, outW, outH, PIX_FMT_RGB24, sws_flag, NULL, NULL, NULL);
            
        }else{
            NSLog(@"vedio avcodec open error");
            return NO;
        }
        
    }else{
        NSLog(@"not finde vedioStream");
        return  NO;
    }
    return YES;
}

-(BOOL) openAudioStream  {
    for (int i=0; i<formatContext->nb_streams; i++) {
        AVStream *stream= formatContext->streams[i];
        if(stream->codec->codec_type==AVMEDIA_TYPE_AUDIO){
            audioStream=stream;
            audioCodecContext=audioStream->codec;
            audioIndex=i;
            break;
        }
    }
    
    if(audioIndex>=0){
        audioCodec= avcodec_find_decoder(audioCodecContext->codec_id);
        int codeResult=avcodec_open2(audioCodecContext, audioCodec, NULL);
        if(codeResult==0){
            
        }else{
            NSLog(@"audio avcodec open error");
            return NO;
        }
    }else{
        NSLog(@"not finde audioStream");
        return  NO;
    }
    return YES;
}

-(BOOL) seekWithTime:(NSTimeInterval)  seekInterval{
    if(seekInterval<0||seekInterval>self.totalTimeInterval){
        return NO;
    }
    
    [readTimer invalidate];
    [readThread cancel];
    [self clearCacheInfo];
   
    int64_t timestamp= seekInterval/av_q2d(vedioStream->time_base);
     NSLog(@"%lu---------%lu------%f",(unsigned long)self.audioFrameArray.count,(unsigned long)self.vedioFrameArray.count,seekInterval);
    if(av_seek_frame(formatContext,vedioIndex,timestamp,AVSEEK_FLAG_BACKWARD)<0){
        return NO;
    }
    @synchronized (self) {
        self.currentVedioInterval=seekInterval;
        self.currentAudioInterval=seekInterval;
        currentSeekInterval=seekInterval;
    }
    [self play];
    return YES;
}

/**
 *  读取要求时间段内的数据（从当前位置开始）
 *
 *  @param readDuration 时间段
 */
-(void) readFrameWithDuation:(CGFloat) readDuration {
    
    CGFloat decodeDuration=0;//记录解码数据的duration
    
    bool isContinueRead=YES;
    while (isContinueRead) {
    
        AVPacket packet;
//        av_init_packet(&packet);
        int codeResult=0;
        @synchronized (self) {
            codeResult=av_read_frame(formatContext,&packet);
        }
        if(codeResult<0){
            self.isEND=YES;
            return;
        }
        
        if(packet.stream_index==vedioIndex){
            DDPacket * vPacket=[DDPacket new];
            vPacket.packetData= [NSMutableData dataWithBytes:&packet length:sizeof(packet)];
            vPacket.best_effort_timestamp=av_q2d(vedioStream->time_base)*packet.pts;
            double pkt_duration=0;
            if(packet.duration!=0){
               pkt_duration=av_q2d(vedioStream->time_base)*packet.duration;
            }else{
               pkt_duration=1.0/av_q2d(vedioStream->r_frame_rate);
            }
            decodeDuration+=pkt_duration;
            vPacket.pkt_duration=pkt_duration;
            
            if(decodeDuration>readDuration){
                isContinueRead=NO;
            }
            if(self.updateCacheVedioInterval){
                self.updateCacheVedioInterval(self.currentVedioCacheInterval);
            }
            @synchronized (self) {
                [self.vedioFrameArray addObject:vPacket];
                self.currentVedioCacheInterval+=pkt_duration;
            }

        }else if(packet.stream_index==audioIndex){
            DDPacket * aPacket=[DDPacket new];
            aPacket.packetData= [NSMutableData dataWithBytes:packet.data length:packet.size];  ;
            aPacket.dataLength=packet.size;
            
            double pkt_duration=0;
            if(packet.duration!=0){
                pkt_duration=av_q2d(vedioStream->time_base)*packet.duration;
            }else{
                pkt_duration=1.0/av_q2d(vedioStream->r_frame_rate);
            }

            aPacket.pkt_duration=pkt_duration;
            @synchronized (self) {
               
                [self.audioFrameArray addObject:aPacket];
                self.currentAudioCahcheInterval+=pkt_duration;
            }
            
            if(self.updateCacheAudioInterval){
                self.updateCacheAudioInterval(self.currentAudioCahcheInterval);
            }
             av_free_packet(&packet);
        }
    }
    
    
}

/**
 *  转换为Image
 *
 *  @param dFrame DDFrame
 *
 *  @return UIImage
 */
-(DDPicture *) convertDDPacketToImage:(DDPacket *) vPacket {
    
    DDPicture *dPicture =[DDPicture new];
    int outW,outH;
    outW=vedioCodecContext->width;
    outH=vedioCodecContext->height;
    AVPacket *packet= [vPacket.packetData mutableBytes];
    
    AVFrame *frame=av_frame_alloc();//解码后的结构体
    int frameRes;
    avcodec_decode_video2(vedioCodecContext, frame, &frameRes, packet);//解码
    if(frameRes){

      
        dPicture.pkt_duration=vPacket.pkt_duration;
        dPicture.pts=av_q2d(vedioStream->time_base)*av_frame_get_best_effort_timestamp(frame);//->best_effort_timestamp;//seek时有问题
        
        AVPicture picture;
        avpicture_alloc(&picture, PIX_FMT_RGB24, outW, outH);//PIX_FMT_RGB24与sws_convert的像素格式一致
        //转换
        sws_scale(rgbConvert, (const uint8_t * const *)frame->data, frame->linesize, 0, vedioCodecContext->height, picture.data, picture.linesize);
        CFDataRef dataRef=CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, picture.data[0], picture.linesize[0]*outH, kCFAllocatorNull);
        CGDataProviderRef providerRef=CGDataProviderCreateWithCFData(dataRef);
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault; //像素中bit的布局
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();//CGColorSpaceCreateDeviceGray //颜色空间
        CGImageRef imageRef=CGImageCreate(outW, outH, 8, 24, picture.linesize[0], colorSpace, bitmapInfo, providerRef, NULL, 0, kCGRenderingIntentDefault);
        CGColorSpaceRelease(colorSpace);
        
        dPicture.image = [UIImage imageWithCGImage:imageRef];
        
        CGImageRelease(imageRef);
        CGDataProviderRelease(providerRef);
        CFRelease(dataRef);
        avpicture_free(&picture);
    }
    av_free(frame);
    av_free_packet(packet);
    return dPicture;
}

@end


