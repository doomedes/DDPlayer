//
//  ViewController.h
//  DDPlayerTest
//
//  Created by yuanyongguo on 16/7/29.
//  Copyright © 2016年 doomedes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDPlayer.h"

@interface ViewController : UIViewController


@property (weak, nonatomic) IBOutlet  DDPlayer *imageView;
@property (weak, nonatomic) IBOutlet UILabel *totalTime;
@property (weak, nonatomic) IBOutlet UISlider *timeSlider;
@property (weak, nonatomic) IBOutlet UILabel *currentTime;


@end

