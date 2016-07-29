//
//  ViewController.m
//  DDPlayerTest
//
//  Created by yuanyongguo on 16/7/29.
//  Copyright © 2016年 doomedes. All rights reserved.
//

#import "ViewController.h"
#import "DDDecoder.h"

@interface ViewController ()
@property(nonatomic,assign) BOOL isDrag;

@end

@implementation ViewController
{
    
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *path=[[NSBundle mainBundle] pathForResource:@"vedio" ofType:@"mp4"];
    //        NSString *path=[[NSBundle mainBundle] pathForResource:@"ryfz" ofType:@"rmvb"];
    //        NSString *path=@"rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov";
    //    NSString *path=[[NSBundle mainBundle] pathForResource:@"audio" ofType:@"mp3"];
    //    [self.imageView.vedioManager  loadVedioFileWithPath:path];
    [self.imageView loadFilePath:path];
    //    [self.timeSlider addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
    [self.timeSlider addTarget:self action:@selector(touchiN:) forControlEvents:UIControlEventTouchDragInside];
    [self.timeSlider addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventTouchUpInside];
}

-(void) touchiN:(UISlider *) slider {
    self.isDrag=YES;
}


-(void) valueChange:(UISlider *)slider {
    
    self.isDrag=NO;
    [self.imageView seekWithTime:slider.value];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if([self.imageView play]){
        NSLog(@"play sunccessful");
        NSTimeInterval total=self.imageView.decoder.totalTimeInterval;
        int h=total/3600;
        int m=(total-h*3600)/60;
        int s=(int)total%60;
        self.totalTime.text=[NSString stringWithFormat:@"%02d:%02d:%02d",h,m,s];
        self.timeSlider.maximumValue=total;
        self.timeSlider.minimumValue=0;
        __weak typeof (self) weakSelf=self;
        self.imageView.decoder.updateVedioInterval=^(NSTimeInterval interval){
            if(weakSelf.isDrag){
                return ;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.timeSlider.value=interval;
                int h=interval/3600;
                int m=(interval-h*3600)/60;
                int s=(int)interval%60;
                weakSelf.currentTime.text=[NSString stringWithFormat:@"%02d:%02d:%02d",h,m,s];
            });
        };
        
    }else{
        NSLog(@"play fail");
    }
}

@end
