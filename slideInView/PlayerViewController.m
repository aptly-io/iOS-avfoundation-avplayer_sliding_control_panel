// Copyright 2016 Francis Meyvis. All rights reserved.

#import "PlayerViewController.h"
#import "GradientView.h"

@import AVFoundation;

@interface PlayerView : UIView
@end

@implementation PlayerView

/// Catch a device rotation; use it to reset the AVPlayerLayer's frame
/// This way the AVPlayerLayer always fit nicely in its view.
- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.layer) {
        self.layer.frame = self.bounds;
    }
}

/// Give this sub class of UIView a AVPlayerLayer type iso CALayer
+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

@end


static NSString *playerItemContext = @"playerItemContext";
static NSString *FILE_URL = @"/Users/franchan/Documents/dev/content/hubblecast.m4v";

/// Font Awesome
/// Find the unicodes here: http://fontawesome.io/cheatsheet/
/// with the help from there: http://fontawesome.io/icons/)
static NSString *faPlayIcon = @"\uf04b";
static NSString *faPauseIcon = @"\uf04c";
static NSString *faInfoIcon = @"\uf05a";
static NSString *faSkipBackIcon = @"\uf049";
static NSString *faSkipForwardIcon = @"\uf050";
static NSString *faSilentVolumeIcon = @"\uf026";
static NSString *faLoudVolumeIcon = @"\uf028";
static NSString *faBanIcon = @"\uf05e";

@implementation PlayerViewController {
    AVPlayer *_player;            ///< controls the playback operation
    IBOutlet UIView *_playerView; ///< holds the video layer
    IBOutlet GradientView *_controlPanelView; ///< holds all playback controls
    BOOL _showingControlPanel;    ///< flags that the control panel is visible
    IBOutlet NSLayoutConstraint *_controlPanelTopConstraint; ///< to animate the control panels appearance
    NSTimer *_controlPanelTimer;  ///< times how long the control panel will be visible
    id _timeObserver;             ///< observes the player's playback offset
    IBOutlet UIButton *_playPauseButton;
    IBOutlet UIButton *_speakerButton;
    IBOutlet UIButton *_muteButton;
    IBOutlet UIButton *_skipBackButton;
    IBOutlet UIButton *_skipForwardButton;
    IBOutlet UISlider *_slider;
    BOOL _sliding;                ///< flags the slider's thumb is dragged

    UIWindow *_secondWindow;
}

/// deallocate observers registered with the NSNotificationCenter
-(void) dealloc
{}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self checkSecondScreen];

    [self setupPlayer];

    [self setupImageLayer];

#if 0
    // Switching dynamically (with a notification) does not work;
    // only when the second display is found at the startup
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(handleScreenDidConnectNotification:)
                   name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleScreenDidDisconnectNotification:)
                   name:UIScreenDidDisconnectNotification object:nil];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // allow full screen by hiding the navigation bar
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    // configure gradient values
    _controlPanelView.layer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.0 green:0.0 blue:0.5 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.0 green:0.0 blue:0.2 alpha:0.3].CGColor
    ];
    
    _sliding = NO;
    
    // An icon to handle air play routing (disabled sound volume bar)
    //#import "MediaPlayer/MediaPlayer.h"
    //    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    //    volumeView.showsVolumeSlider = NO;
    //    [volumeView sizeToFit];
    //    [_controlPanelView addSubview:volumeView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark Action handlers

/// clicked the play/pause button
- (IBAction)playPauseAction:(id)sender
{
    if (AVPlayerStatusReadyToPlay == _player.status && 0.0 == _player.rate) {
        [_player play];
        [_playPauseButton setTitle:faPauseIcon forState:UIControlStateNormal];
        [self showControlPanel];
    } else {
        [_player pause];
        [_playPauseButton setTitle:faPlayIcon forState:UIControlStateNormal];
        [self showControlPanel];
    }
}

/// Clicked the speaker button
- (IBAction)speakerAction:(id)sender
{
    _muteButton.enabled = YES;
    _muteButton.hidden = NO;
    _player.muted = NO;
    [self showControlPanel];
}

/// Clicked the mute button
- (IBAction)muteAction:(id)sender
{
    _muteButton.enabled = NO;
    _muteButton.hidden = YES;
    _player.muted = YES;
    [self showControlPanel];
}

/// Clicked the skip back button
- (IBAction)skipbackAction:(id)sender
{
    CMTime time = _player.currentItem.currentTime;
    if (CMTIME_IS_VALID(time)) {
        time = CMTimeAdd(time, CMTimeMakeWithSeconds(-10.0, NSEC_PER_SEC));
        [_player seekToTime:time];
    }
    [self showControlPanel];
}

/// Clicked the skip forward button
- (IBAction)skipforwardAction:(id)sender
{
    CMTime time = _player.currentItem.currentTime;
    if (CMTIME_IS_VALID(time)) {
        time = CMTimeAdd(time, CMTimeMakeWithSeconds(10.0, NSEC_PER_SEC));
        [_player seekToTime:time];
    }
    [self showControlPanel];
}

/// Dragged the slider
- (IBAction)seekAction:(id)sender
{
    CMTime time = CMTimeMakeWithSeconds(_slider.value, NSEC_PER_SEC);
    [_player seekToTime:time];
    [self showControlPanel];
}

/// Detect start of the manipulation of the seekbar
/// Disable the control panel timeout and
/// avoid that the time observer manipulates the slider
- (IBAction)seekTouchDragInside:(id)sender
{
    _sliding = YES; // prevent time observer from updating the slider
    [self showControlPanel];
    [_controlPanelTimer invalidate]; // but remove its timeout
    _controlPanelTimer = nil;
}

/// Detect stopping of the seekbar; give te time observer access again
- (IBAction)seekTouchUpOutside:(id)sender
{
    _sliding = NO; // allow time observer to update the slider
}

/// Clicked the show controlPanel button
- (IBAction)toggleControlPanel:(id)sender
{
    if (!_showingControlPanel) {
        [self showControlPanel];
    } else {
        [self hideControlPanel];
    }
}

#pragma mark Notifications

- (void)handleScreenDidConnectNotification:(NSNotification*)aNotification
{
    if (!_secondWindow) {
        UIScreen *screen = [aNotification object];
        [self handleSecondScreen:screen];
    }
}

- (void)handleScreenDidDisconnectNotification:(NSNotification*)aNotification
{
    if (_secondWindow) {
        _secondWindow.hidden = YES;
        _secondWindow = nil;
    }
}

#pragma mark Observers

/// Listen in on player's state changes
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary<NSString *,id> *)change
                      context:(void *)context
{
    if (context == &playerItemContext) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            AVPlayerItem *playerItem = (AVPlayerItem*)object;
            switch (playerItem.status) {
                    
                case AVPlayerItemStatusReadyToPlay:
                    _playPauseButton.enabled = YES;
                    _slider.maximumValue = playerItem.duration.value / playerItem.duration.timescale;
                    [_playPauseButton setTitle:faPlayIcon forState:UIControlStateNormal];
                    
                    [self addTimeObserver];
                    
                    break;
                    
                case AVPlayerItemStatusFailed: {
                    NSData *errorData = [playerItem.errorLog extendedLogData];
                    if (errorData) {
                        NSString *error = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
                        NSLog(@"error: %@", error);
                    }
                    NSData *accessData = [playerItem.accessLog extendedLogData];
                    if (accessData) {
                        NSString *access = [[NSString alloc] initWithData:accessData encoding:NSUTF8StringEncoding];
                        NSLog(@"access: %@", access);
                    }
                    _playPauseButton.enabled = NO;
                }
                    break;
                    
                default:
                    break;
            }
        });
    }
}

#pragma mark Internal - control panel

/// Hide the control panel after the timeout elapses
-(void) handelControlPanelTimeout:(NSTimer *)timer
{
    _controlPanelTimer = nil;
    [self hideControlPanel];
}

/// Cancel an ongoing control panel timeout and install a fresh one
-(void) setControlPanelTimeout
{
    [_controlPanelTimer invalidate];
    _controlPanelTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                          target:self
                                                        selector:@selector(handelControlPanelTimeout:)
                                                        userInfo:nil
                                                         repeats:NO];
}

/// Slide down the control panel with animation from whatever is its position
/// Install a timer that hides the panel after some time (e.g. inactivity)
-(void) showControlPanel
{
    _showingControlPanel = YES;
    [self setControlPanelTimeout];  // make sure the panel hides after some time
    [self.view layoutIfNeeded];     // re-layout to have an animation effect
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState |
    UIViewAnimationOptionAllowUserInteraction;
    [UIView animateWithDuration:0.5 // slide-in with dignity
                          delay:0.0 // no delay necessary
                        options:options
                     animations:^{
                         _controlPanelTopConstraint.constant = 0.0f;
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

/// Slide up the control panel with animation from whatever is its position
-(void) hideControlPanel
{
    _showingControlPanel = NO;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.2 // slide away fast
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         _controlPanelTopConstraint.constant = -100.0f;
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

#pragma mark Internal - player

- (void) setupPlayer
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"content.bundle/hubblecast" withExtension:@"m4v"];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSLog(@"filename: %@", asset.URL.lastPathComponent);

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [playerItem addObserver:self forKeyPath:@"status" options:0 context:&playerItemContext];
    _player = [AVPlayer playerWithPlayerItem:playerItem];
    
    [(AVPlayerLayer *)_playerView.layer setPlayer:_player];
    
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)_playerView.layer;
    // respect video's original aspect ratio, scale without cliping in its view
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    playerLayer.needsDisplayOnBoundsChange = YES;
    
    // allow for airplay (the default)
    [_player setAllowsExternalPlayback:YES];
    [_player setExternalPlaybackVideoGravity: AVLayerVideoGravityResizeAspect];
#if 1
    // Continues the Airplay mirroring; does not switch over to Airplay Video
    [_player setUsesExternalPlaybackWhileExternalScreenIsActive:NO];
#else
    // Will trigger Airplay Video; it stops Airplay mirroring
    [_player setUsesExternalPlaybackWhileExternalScreenIsActive:YES];
#endif
}

- (void)setupImageLayer
{
    if (_player) {
        UIImage* image = [UIImage imageNamed:@"content.bundle/franchan.png"];

        CALayer *imageLayer = [CALayer layer];
        imageLayer.contents = (id) image.CGImage;
        CGSize imageSize = image.size;
        imageLayer.bounds = CGRectMake(0.0f, 0.0f, imageSize.width/4, imageSize.height/4);
        imageLayer.position = CGPointMake(460.0f, 460.0f);

        AVPlayerLayer *playerLayer = (AVPlayerLayer *)_playerView.layer;
        [playerLayer addSublayer:imageLayer];

        // ? Put the image directly on the AVPlayerLayer?
    }
}

/// Install a periodic timer that updates the seek bar
-(void) addTimeObserver
{
    CMTime interval = CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC);
    
    void (^block)(CMTime time) = ^(CMTime time) {
        // only update if the seek bar's handle is not dragged
        if (!_sliding) {
            time = _player.currentItem.currentTime;
            if (CMTIME_IS_VALID(time)) {
                // update the seek bar with the player's current position
                NSTimeInterval offset = CMTimeGetSeconds(time);
                _slider.value = offset;
            }
        }
    };
    
    _timeObserver = [_player addPeriodicTimeObserverForInterval:interval
                                                          queue:dispatch_get_main_queue()
                                                     usingBlock:block];
}

-(void)checkSecondScreen
{
    if ([[UIScreen screens] count] == 2) {
        UIScreen* screen = [[UIScreen screens] lastObject];
        [self handleSecondScreen:screen];
    }
}

- (void)handleSecondScreen:(UIScreen*)screen
{
    if (nil != screen) {
        CGRect screenBounds = screen.bounds;

        _secondWindow = [[UIWindow alloc] initWithFrame:screenBounds];
        _secondWindow.screen = screen;
        _secondWindow.rootViewController = self;
        _secondWindow.hidden = NO;
    }
}


@end
