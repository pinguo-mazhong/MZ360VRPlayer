//
//  MZPlayerViewController.m
//  EapilDemo
//
//  Created by mazhong on 16/4/18.
//  Copyright © 2016年 mazhong. All rights reserved.
//

#import "MZPlayerViewController.h"
#import <VIMVideoPlayerView.h>
#import <VIMVideoPlayer.h>
#import <MDVRLibrary.h>

#define HIDE_CONTROL_DELAY 5.0f
#define DEFAULT_VIEW_ALPHA 0.6f

@interface MZPlayerViewController () <VIMVideoPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIView *controlPane;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *motionButton;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (nonatomic) VIMVideoPlayerView *videoPlayerView;
@property (nonatomic) MDVRLibrary *vrLibrary;
@property (nonatomic) AVPlayerItem *playerItem;

@end

@implementation MZPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;

    [self initPlayer];
    [self initUI];
    [self initActions];
    [self hideControlsSlowly];
}

- (void)initUI
{
    self.controlPane.layer.cornerRadius = 8;
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"thumb"] forState:UIControlStateNormal];
    [self.volumeSlider setThumbImage:[UIImage imageNamed:@"thumb"] forState:UIControlStateNormal];
}

- (void)initActions
{
    [self.progressSlider addTarget:self action:@selector(scrubbedBySlider:) forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self.videoPlayerView.player action:@selector(stopScrubbing) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel];

    [self.volumeSlider addTarget:self action:@selector(changeVolumeBySlider:) forControlEvents:UIControlEventValueChanged];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControls)];
    [self.view addGestureRecognizer:tap];
}

- (void) initPlayer{
    // video player
    self.videoPlayerView = [[VIMVideoPlayerView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    self.videoPlayerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.videoPlayerView.player.delegate = self;
    [self.videoPlayerView setVideoFillMode:AVLayerVideoGravityResizeAspect];
    [self.videoPlayerView.player enableTimeUpdates];
    [self.videoPlayerView.player enableAirplay];

    self.playerItem = [[AVPlayerItem alloc] initWithURL:self.videoURL];
    [self.videoPlayerView.player setPlayerItem:self.playerItem];
    [self.videoPlayerView.player play];


    // MDVRLibrary
    MDVRConfiguration* config = [MDVRLibrary createConfig];

    [config displayMode:MDModeDisplayNormal];
    [config interactiveMode:MDModeInteractiveMotion];
    [config asVideo:self.playerItem];
    [config setContainer:self view:self.view];

    self.vrLibrary = [config build];
}

- (NSString *)humanReadableStringForseconds:(NSUInteger)time
{
    NSInteger hours = floor(time / 3600);
    NSInteger minutes = floor(time % 3600 / 60);
    NSInteger seconds = floor(time % 3600 % 60);
    NSString *humanReadableString = [NSString stringWithFormat:@"%02li:%02li:%02li",(long)hours, (long)minutes, (long)seconds];
    return humanReadableString;
}

- (IBAction)playButtonTapped:(UIButton *)sender {
    if (self.videoPlayerView.player.isPlaying) {
        [self.videoPlayerView.player pause];
    } else {
        [self.videoPlayerView.player play];
    }
    [self updatePlayButton];
}

- (void)updatePlayButton
{
    if (self.videoPlayerView.player.isPlaying) {
        [self.playButton setImage:[UIImage imageNamed:@"playback_pause"] forState:UIControlStateNormal];
    } else {
        [self.playButton setImage:[UIImage imageNamed:@"playback_play"] forState:UIControlStateNormal];
    }
}

- (IBAction)motionButtonTapped:(UIButton *)sender {
    [self.vrLibrary switchInteractiveMode];
    [self updateMotionButton];
}

- (void)updateMotionButton
{
    if ([self.vrLibrary getInteractiveMdoe] == MDModeInteractiveTouch) {
        [self.motionButton setImage:[UIImage imageNamed:@"ipadmove_unselected"] forState:UIControlStateNormal];
    } else if ([self.vrLibrary getInteractiveMdoe] == MDModeInteractiveMotion)
    {
        [self.motionButton setImage:[UIImage imageNamed:@"ipadmove"] forState:UIControlStateNormal];
    }
}

- (IBAction)backButtonTapped:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)scrubbedBySlider:(UISlider *)slider
{
    CMTime playerDuration = [self.playerItem duration];
    CGFloat totolSeconds = CMTimeGetSeconds(playerDuration);
    CGFloat currentSecond = (slider.value - slider.minimumValue) / (slider.maximumValue - slider.minimumValue) * totolSeconds;
    [self.videoPlayerView.player scrub:currentSecond];
}

- (void)changeVolumeBySlider:(UISlider *)slider
{
    CGFloat value = MAX(0, slider.value);
    value = MIN(1, slider.value);
    [self.videoPlayerView.player setVolume:value];
}

#pragma mark - controlPane

-(void)toggleControls {
    if(self.controlPane.hidden){
        [self showControlsFast];
    }else{
        [self hideControlsFast];
    }

    [self scheduleHideControls];
}

-(void)scheduleHideControls {
    if(!self.controlPane.hidden) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(hideControlsSlowly) withObject:nil afterDelay:HIDE_CONTROL_DELAY];
    }
}

-(void)hideControlsWithDuration:(NSTimeInterval)duration {
    self.controlPane.alpha = DEFAULT_VIEW_ALPHA;
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^(void) {

                         self.controlPane.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         if(finished)
                             self.controlPane.hidden = YES;
                     }];

}

-(void)hideControlsFast {
    [self hideControlsWithDuration:0.2];
}

-(void)hideControlsSlowly {
    [self hideControlsWithDuration:1.0];
}

-(void)showControlsFast {
    self.controlPane.alpha = 0.0;
    self.controlPane.hidden = NO;
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^(void) {

                         self.controlPane.alpha = DEFAULT_VIEW_ALPHA;
                     }
                     completion:nil];
}

#pragma mark - VIMVideoPlayerDelegate

- (void)videoPlayer:(VIMVideoPlayer *)videoPlayer timeDidChange:(CMTime)cmTime
{
    CMTime playerDuration = [self.playerItem duration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        self.progressSlider.minimumValue = 0.0;
        return;
    }

    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [self.progressSlider minimumValue];
        float maxValue = [self.progressSlider maximumValue];
        double time = CMTimeGetSeconds(cmTime);

        self.progressSlider.value = (maxValue - minValue) * time / duration + minValue;
        double leftSeconds = duration - time;
        NSString *leftTime = [self humanReadableStringForseconds:leftSeconds];
        NSString *currentTime = [self humanReadableStringForseconds:time];
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%@", currentTime];
        self.leftTimeLabel.text = [NSString stringWithFormat:@"-%@", leftTime];
    }
}

- (void)videoPlayerDidReachEnd:(VIMVideoPlayer *)videoPlayer
{
    [self updatePlayButton];
}

@end
