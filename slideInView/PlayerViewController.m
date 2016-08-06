//  Copyright 2016 Francis Meyvis. All rights reserved.

//  ViewController.m
//  slideInView

#import "PlayerViewController.h"

@import AVFoundation;

@interface PlayerViewController ()

@property (strong, nonatomic) IBOutlet UIView *playerView;
@property (strong, nonatomic) IBOutlet UIButton *playPauseButton;

@end

static NSString *playerItemContext = @"playerItemContext";

@implementation PlayerViewController {
    
    AVPlayer *_player;
    AVPlayerLayer *_playerLayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupPlayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Action handlers

- (IBAction)playPauseAction:(id)sender {
    if (_player.status == AVPlayerStatusReadyToPlay &&
        0.0 == _player.rate) {
        [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        [_player play];
    } else {
        [self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
        [_player pause];
    }
}

#pragma mark Observers

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
                    self.playPauseButton.enabled = YES;
                    [self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
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
                    self.playPauseButton.enabled = NO;
                }
                    break;
                default:
                    break;
            }
        });
    }
}

//-(void)viewDidLayoutSubviews
//{
//    [super viewDidLayoutSubviews];
//    _playerView.frame = _playerView.bounds;
//}

#pragma mark Internal

- (void) setupPlayer
{
    NSURL *url = [NSURL fileURLWithPath:@"/Users/franchan/Documents/dev/content/hubblecast.m4v"];
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [playerItem addObserver:self forKeyPath:@"status" options:0 context:&playerItemContext];
    _player = [AVPlayer playerWithPlayerItem:playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    // by default layer is a CGRectZero; video image would not be visible
    _playerLayer.frame = self.playerView.bounds;
    [self.playerView.layer addSublayer:_playerLayer];
}
@end
