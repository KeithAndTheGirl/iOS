//
//  KATGAudioPlayerController.m
//  KATG
//
//  Created by Doug Russell on 3/17/12.
//  Copyright (c) 2012 Doug Russell. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "KATGAudioPlayerController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "KATGAudioSessionManager.h"

NSString *const KATGCurrentTimeObserverKey = @"currentTime";
NSString *const KATGDurationObserverKey = @"availabelDuration";
NSString *const KATGStateObserverKey = @"state";

static NSString *const KATGAudioPlayerStatusKeyPath = @"status";
static NSString *const KATGAudioPlayerLoadedTime = @"loadedTimeRanges";
static NSString *const KATGAudioPlayerRateKeyPath = @"rate";

static void *KATGAudioPlayerStatusObserverContext = @"StatusObserverContext";
static void *KATGAudioPlayerRateObserverContext = @"RateObserverContext";

@interface KATGAudioPlayerController ()

@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) AVPlayerItem *avPlayerItem;

@property (nonatomic) CMTime currentTime;

// track this so it can be removed when avplayer is recreated
@property (nonatomic) id timeObserver;
// track this so it can be removed when playback ends
@property (nonatomic) id didEndObserver;

@property (nonatomic) bool isApplicationActive;

@property NSInteger fileSize;

- (instancetype)initWithURL:(NSURL *)url;

@end

@implementation KATGAudioPlayerController

@synthesize avPlayer = _avPlayer;

#pragma mark - Init/Dealloc

+ (instancetype)audioPlayerWithURL:(NSURL *)url
{
	return [[[self class] alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url
{
	self = [super init];
	if (self)
	{
		_url = [url copy];
		_state = KATGAudioPlayerStateUnknown;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
		_isApplicationActive = (bool)([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive);
	}
	return self;
}

- (void)dealloc
{
	if (_avPlayerItem != nil)
	{
		[_avPlayerItem removeObserver:self forKeyPath:KATGAudioPlayerStatusKeyPath context:KATGAudioPlayerStatusObserverContext];
		[_avPlayerItem removeObserver:self forKeyPath:KATGAudioPlayerLoadedTime context:KATGAudioPlayerStatusObserverContext];
		[[NSNotificationCenter defaultCenter] removeObserver:self.didEndObserver];
	}
	if (self.avPlayer != nil)
	{
		[self.avPlayer removeObserver:self forKeyPath:KATGAudioPlayerRateKeyPath context:KATGAudioPlayerRateObserverContext];
		[self.avPlayer setRate:0.0f];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - 

- (void)willResignActive:(NSNotification *)notification
{
	self.isApplicationActive = false;
}

- (void)didBecomeActive:(NSNotification *)notification
{
	self.isApplicationActive = true;
}

#pragma mark - Accessors

- (void)setUrl:(NSURL *)url
{
	if (_url != url)
	{
		[self.avPlayer setRate:0.0f];
		self.avPlayerItem = nil;
		self.avPlayer = nil;
		_url = url;
	}
}

+ (BOOL)automaticallyNotifiesObserversOfState
{
	return NO;
}

- (void)setState:(KATGAudioPlayerState)state
{
	if (_state != state)
	{
		_state = state;
		[self.delegate player:self didChangeState:_state];
	}
}

- (void)setAvPlayerItem:(AVPlayerItem *)avPlayerItem
{
	if (_avPlayerItem != avPlayerItem)
	{
		if (_avPlayerItem != nil)
		{
			[_avPlayerItem removeObserver:self forKeyPath:KATGAudioPlayerStatusKeyPath context:KATGAudioPlayerStatusObserverContext];
			[_avPlayerItem removeObserver:self forKeyPath:KATGAudioPlayerLoadedTime context:KATGAudioPlayerStatusObserverContext];

			[[NSNotificationCenter defaultCenter] removeObserver:self.didEndObserver];
			self.didEndObserver = nil;
		}
		_avPlayerItem = avPlayerItem;
		if (_avPlayerItem != nil)
		{
			[_avPlayerItem addObserver:self forKeyPath:KATGAudioPlayerStatusKeyPath options:0 context:KATGAudioPlayerStatusObserverContext];
			[_avPlayerItem addObserver:self forKeyPath:KATGAudioPlayerLoadedTime options:0 context:KATGAudioPlayerStatusObserverContext];
            
            self.availabelDuration = _avPlayerItem.asset.duration;
			__weak KATGAudioPlayerController *weakSelf = self;
			self.didEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:_avPlayerItem queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
				weakSelf.state = KATGAudioPlayerStateDone;
			}];
		}
	}
}

- (void)setAvPlayer:(AVPlayer *)avPlayer
{
	if (_avPlayer != avPlayer)
	{
		if (_avPlayer != nil)
		{
			[_avPlayer removeObserver:self forKeyPath:KATGAudioPlayerRateKeyPath context:KATGAudioPlayerRateObserverContext];
			[_avPlayer removeTimeObserver:self.timeObserver];
			[_avPlayer setRate:0.0f];
		}
		_avPlayer = avPlayer;
		if (_avPlayer != nil)
		{
			[_avPlayer addObserver:self forKeyPath:KATGAudioPlayerRateKeyPath options:0 context:KATGAudioPlayerRateObserverContext];

			__weak KATGAudioPlayerController *weakSelf = self;
			self.timeObserver = [_avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:nil usingBlock:^(CMTime time) {
				weakSelf.currentTime = time;
                
                if ([weakSelf.url checkResourceIsReachableAndReturnError:nil]) {
                    AVAsset *asset = [AVAsset assetWithURL:weakSelf.url];
                    double currentDuration = CMTimeGetSeconds(weakSelf.avPlayerItem.asset.duration);
                    double fileDuration = CMTimeGetSeconds(asset.duration);
                    double currentTime = CMTimeGetSeconds(weakSelf.currentTime);
                    if((fileDuration - currentDuration > 5*60) ||
                       (currentDuration < fileDuration-1 && currentDuration - currentTime < 10) ||
                       (currentDuration < fileDuration-1 && fileDuration > weakSelf.totalDurationSeconds-1)) {
                            BOOL currentlyPlaying = weakSelf.avPlayer.rate > 0;
                            if(currentlyPlaying)
                                [weakSelf.avPlayer pause];
                            AVPlayerItem *newItem = [AVPlayerItem playerItemWithAsset:asset];
                            [weakSelf.avPlayer replaceCurrentItemWithPlayerItem:newItem];
                            [weakSelf.avPlayer seekToTime:weakSelf.currentTime];
                            if(currentlyPlaying)
                                [weakSelf.avPlayer play];
                            weakSelf.avPlayerItem = newItem;
                            NSLog(@"New length: %@", [weakSelf stringFromTime:asset.duration]);
                    }
                }
			}];
		}
		self.currentTime = CMTimeMake(0, 0);
		self.availabelDuration = CMTimeMake(0, 0);
	}
}

-(NSString*)stringFromTime:(CMTime)time {
    Float64 sec = CMTimeGetSeconds(time);
    return [NSString stringWithFormat:@"%2i:%2i:%2i", (int)(sec/3600), (int)(((int)sec%3600)/60), ((int)sec)%60];
}

- (void)setAvailabelDuration:(CMTime)availabelDuration {
	if (CMTimeCompare(availabelDuration, _availabelDuration) != 0)
	{
		_availabelDuration = availabelDuration;
		[self.delegate player:self didChangeDuration:_availabelDuration];
	}
}

#pragma mark - KVO

NS_INLINE BOOL KATGFloatEqual(float A, float B)
{
	return (BOOL)(fabs(A - B) < 0.0000001);
}

- (void)updateState
{
	CGFloat rate = self.avPlayer.rate;
	AVPlayerItemStatus status = self.avPlayerItem.status;
    self.availabelDuration = self.avPlayerItem.duration;
    self.error = self.avPlayerItem.error?self.avPlayerItem.error:self.avPlayer.error;
	if (status == AVPlayerItemStatusFailed)
	{
		self.state = KATGAudioPlayerStateFailed;
		self.avPlayerItem = nil;
		self.avPlayer = nil;
		return;
	}
    else if(status == AVPlayerItemStatusReadyToPlay && self.state == KATGAudioPlayerStateLoading) {
        [self.avPlayer prerollAtRate:1 completionHandler:^(BOOL finished) {
            if(finished )
                [self.avPlayer play];
        }];
    }
	if (KATGFloatEqual(rate, 0.0f))
	{
        if(self.state != KATGAudioPlayerStateLoading) {
            self.state = KATGAudioPlayerStatePaused;
        }
	}
	else if (KATGFloatEqual(rate, 1.0f))
	{
        if (status == AVPlayerItemStatusUnknown)
		{
			self.state = KATGAudioPlayerStateLoading;
		}
		else
		{
			self.state = KATGAudioPlayerStatePlaying;
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ((context == KATGAudioPlayerStatusObserverContext) ||
	    (context == KATGAudioPlayerRateObserverContext))
	{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateState];
        });
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - Actions

- (void)play
{
	if (self.url == nil)
	{
		NSLog(@"Attempted play with nil URL");
		return;
	}
	if (self.avPlayerItem == nil)
	{   
        AVURLAsset *asset = [AVURLAsset assetWithURL:self.url];
        self.avPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
        NSLog(@"First region: %@", [self stringFromTime:asset.duration]);
		if (self.avPlayerItem == nil)
		{
			NSLog(@"Failed to create avplayeritem with URL %@", self.url);
			return;
		}
	}
	if (self.avPlayer == nil)
	{
		self.avPlayer = [AVPlayer playerWithPlayerItem:self.avPlayerItem];
		if (self.avPlayer == nil)
		{
			NSLog(@"Failed to create avplayer with avplayeritem %@", self.avPlayerItem);
			return;
		}
	}
    if(self.avPlayer.currentItem == nil)
        [self.avPlayer replaceCurrentItemWithPlayerItem:self.avPlayerItem];
	KATGConfigureAudioSessionState(KATGAudioSessionStatePlayback);
	
    [self.avPlayer play];
}

- (void)pause
{
	[self.avPlayer pause];
    [self.avPlayer replaceCurrentItemWithPlayerItem:nil];
    self.state = KATGAudioPlayerStatePaused;
}

- (void)seekToTime:(CMTime)currentTime
{
	[self.avPlayer seekToTime:currentTime];
	_currentTime = currentTime;
}

@end
