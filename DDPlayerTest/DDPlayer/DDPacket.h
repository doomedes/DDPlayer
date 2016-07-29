//
//  DDPacket.h
//  FFMPEGDemo
//
//  Created by yuanyongguo on 16/7/28.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DDPacket : NSObject


//@property(nonatomic,assign) int64_t pts;

@property(nonatomic,strong) NSMutableData * packetData; //解码转换后的data

//@property(nonatomic,assign) int bytesPerRow;  //每一行的数据大小 (针对图片数据)
//
@property(nonatomic,assign) int dataLength;  //图片：整张图片的总长度＝每一行的数据大小＊高度 音频：数据大小
//
//@property(nonatomic,assign) int decodecPacketLen; //对应packet解码的大小
//
@property(nonatomic,assign) CGFloat best_effort_timestamp; //播放时间(显示时间)

@property(nonatomic,assign) CGFloat pkt_duration; //播放时长（显示时长）




@end
