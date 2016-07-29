# DDPlayer
使用FFMPeg实现的一个播放器

注意FFMPeg的配置可以在网上查找！

DDPlayer分为三部分： <br />
DDAudioManager 音频播放队列 <br />
DDDecoder   视频文件解码 <br />
DDPlayer   通过DDDecoder解码将音频数据与视频帧分别通过DDAudioManager添加到音频播放队列中，将视频帧转换为图片显示！ <br />
具体逻辑可以查看代码代码 <br />


<pre><code>

@interface DDPlayer : UIImageView

@property(nonatomic,strong) DDAudioManager *audioManager;
@property(nonatomic,assign) Status  status;//状态
@property(nonatomic,strong) DDDecoder *decoder;
@property(nonatomic,assign) NSTimeInterval  currentVedioInterval;//当前视频播放进度
@property(nonatomic,assign) NSTimeInterval  currentAudioInterval;//当前音频播放进度

-(BOOL) play; //开始播放
-(void) pause;
-(void) stop;
-(BOOL) seekWithTime:(NSTimeInterval) seekInterval;
-(BOOL) loadFilePath:(NSString *) filePath; //load要播放的视频文件或者url

@end
</code></pre>

使用方式：
<pre><code>

@property (weak, nonatomic) IBOutlet  DDPlayer *imageView;

  NSString *path=[[NSBundle mainBundle] pathForResource:@"vedio" ofType:@"mp4"];
  [self.imageView loadFilePath:path];
  [self.imageView play]
</code></pre>

播放效果：
![Alt text](https://github.com/doomedes/DDPlayer/blob/master/player.png)


项目还不是很完善，会继续改进....
