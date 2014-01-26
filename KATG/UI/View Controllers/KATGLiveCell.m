//
//  KATGLiveCell.m
//  KATG
//
//  Created by Timothy Donnelly on 12/8/12.
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

#import "KATGLiveCell.h"
#import "KATGContentContainerView.h"
#import "KATGScheduledEvent.h"
#import "KATGButton.h"
#import "KATGControlButton.h"
#import "KATGCigaretteSmokeView.h"
#import "KATGBeerBubblesView.h"
#import "KATGPlaybackManager.h"
#import "UIColor+KATGColors.h"
#import "KATGDataStore.h"

@interface KATGTimerTarget : NSProxy
@property (weak, nonatomic) id target;
@end
@implementation KATGTimerTarget
- (id)forwardingTargetForSelector:(SEL)aSelector
{
	id target = self.target;
	NSAssert(target, @"Timer target has gone to nil. This will crash and is probably caused by not cleaning up the timer associated with this target.");
	return target;
}
@end


@implementation KATGLiveCell

#pragma mark - 

-(void)awakeFromNib {
    [self.internalView removeFromSuperview];
    [self.contentView addSubview:self.internalView];
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat height = 0;
    if(screenHeight > 480)
        height = 52;
    
    self.internalView.frame = CGRectMake(0, height, self.contentView.frame.size.width, self.internalView.frame.size.height);
    
    self.contentView.backgroundColor = [UIColor blackColor];
    
    [_countLabelHours.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [_countLabelHours.layer setBorderWidth:0.5];
    [_countLabelHours.layer setCornerRadius:4];
    
    [_countLabelMinutes.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [_countLabelMinutes.layer setBorderWidth:0.5];
    [_countLabelMinutes.layer setCornerRadius:4];
    
    [_countLabelSeconds.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [_countLabelSeconds.layer setBorderWidth:0.5];
    [_countLabelSeconds.layer setCornerRadius:4];
    
    [_feedbackButton.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [_feedbackButton.layer setBorderWidth:0.5];
    [_feedbackButton.layer setCornerRadius:4];
    
	_liveToggleButton.hidden = YES;
#if DEBUG
    _liveToggleButton.hidden = NO;
#endif
    self.currentAudioPlayerState = KATGAudioPlayerStateUnknown;
    
    _target = [KATGTimerTarget alloc];
    _target.target = self;
    
    _timer = [NSTimer timerWithTimeInterval:1.0f target:_target selector:@selector(updateCounter) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
    [self addPlaybackManagerKVO];
}

- (void)dealloc
{
	[_timer invalidate];
	[self removePlaybackManagerKVO];
}

- (void)prepareForReuse
{
	[super prepareForReuse];
}

#pragma mark - 

- (IBAction)sendFeedbackButtonPressed:(id)sender
{
	[self.liveShowDelegate liveShowFeedbackButtonTapped:self];
}

#pragma mark - 

- (void)layoutSubviews
{
	[super layoutSubviews];
	[self layoutLiveMode];
}

- (void)layoutLiveMode
{
	BOOL liveMode = self.liveMode;
	
	self.playButton.alpha = liveMode ? 1.0f : 0.0f;
	self.feedbackButton.alpha = liveMode ? 1.0f : 0.0f;
	self.onAirLabel.alpha = liveMode ? 1.0f : 0.0f;
    self.timerSection.alpha = liveMode ? 0:1;
    self.titleLabel.alpha = liveMode ? 0:1;
    
	self.loadingIndicator.center = self.playButton.center;
    
    self.descriptionLabel.text = liveMode ? @"Hosts Keith and Chemda respond to real-time feedback live on the show" : @"You will be able to listen to the show live and send feedback directly to hosts Keith and Chemda. They respond to listener feedback live on the show.";
}

#pragma mark - Counter State

- (void)updateCounter
{
	if (!self.timestamp || self.liveMode)
	{
		return;
	}
	NSDateComponents *components = [self currentComponents];
    if([[NSDate date] timeIntervalSinceDate:self.timestamp] > 0) {
        [[KATGDataStore sharedStore] pollForData];
        return;
    }
	self.countLabelHours.text = [NSString stringWithFormat:@"%d", components.hour];
	self.countLabelMinutes.text = [NSString stringWithFormat:@"%02d", components.minute];
	self.countLabelSeconds.text = [NSString stringWithFormat:@"%02d", components.second];
	self.nextShowLabel.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"The next show will begin in %d hours %d minutes %d seconds", nil), components.hour, components.minute, components.second];
}

- (NSDateComponents *)currentComponents
{
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:[NSDate date] toDate:self.timestamp options:0];
	return components;
}

- (void)setCountLabelDefaultText
{
    self.countLabelHours.text = @"00";
	self.countLabelMinutes.text = @"00";
	self.countLabelSeconds.text = @"00";
}

- (void)setTimestamp:(NSDate *)timestamp
{
	if (timestamp != _timestamp)
	{
		_timestamp = timestamp;
		if (_timestamp)
		{
			[self updateCounter];
		}
		else
		{
			[self setCountLabelDefaultText];
		}
	}
}

#pragma mark - state

- (void)setLiveMode:(bool)liveMode
{
	[self setLiveMode:liveMode animated:NO];
}

- (void)setLiveMode:(bool)liveMode animated:(BOOL)animated
{	
	_liveMode = liveMode;
	[UIView animateWithDuration:animated ? 0.3f : 0.0f
					 animations:^{
						 [self layoutLiveMode];
					 } completion:^(BOOL finished) {
						 
					 }];
}

- (IBAction)toggleLive:(id)sender
{
    [[KATGDataStore sharedStore] setTestLiveMode:!_liveMode];
}

#pragma mark - Playback controls

- (IBAction)playButtonTapped:(id)sender
{
	if ([[KATGPlaybackManager sharedManager] isLiveShow])
	{
		if ([[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying)
		{
			[[KATGPlaybackManager sharedManager] pause];
		}
		else
		{
			[[KATGPlaybackManager sharedManager] play];
		}
	}
	else
	{
		[[KATGPlaybackManager sharedManager] configureForLiveShow];
		[[KATGPlaybackManager sharedManager] play];
	}
}

-(void)updateViewState {
	if (_currentAudioPlayerState == KATGAudioPlayerStateLoading)
	{
		[self.loadingIndicator startAnimating];
	}
	else
	{
		[self.loadingIndicator stopAnimating];
	}
	switch (_currentAudioPlayerState)
	{
		case KATGAudioPlayerStateDone:
		{
			self.playButton.enabled = YES;
			[_playButton setImage:[UIImage imageNamed:@"PlayLiveButton.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStateFailed:
		{
			self.playButton.enabled = YES;
			[_playButton setImage:[UIImage imageNamed:@"PlayLiveButton.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStateLoading:
		{
			self.playButton.enabled = NO;
			[_playButton setImage:nil forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStatePaused:
		{
			self.playButton.enabled = YES;
			[_playButton setImage:[UIImage imageNamed:@"PlayLiveButton.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStatePlaying:
		{
			self.playButton.enabled = YES;
			[_playButton setImage:[UIImage imageNamed:@"StopLiveButton.png"] forState:UIControlStateNormal];
			break;
		}
		case KATGAudioPlayerStateUnknown:
		{
			self.playButton.enabled = YES;
			[_playButton setImage:[UIImage imageNamed:@"PlayLiveButton.png"] forState:UIControlStateNormal];
			break;
		}
	}
}

- (void)setCurrentAudioPlayerState:(KATGAudioPlayerState)currentAudioPlayerState
{
    _currentAudioPlayerState = currentAudioPlayerState;
    [self performSelector:@selector(updateViewState) withObject:nil afterDelay:0.2];
}

#pragma mark - KATGPlaybackManager

- (void)addPlaybackManagerKVO
{
	[[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:KATGStateObserverKey options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
}

- (void)removePlaybackManagerKVO
{
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:KATGStateObserverKey];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:KATGStateObserverKey])
	{
		if ([[KATGPlaybackManager sharedManager] isLiveShow])
		{
			CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
				self.currentAudioPlayerState = [[KATGPlaybackManager sharedManager] state];
			});
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -

- (void)setScheduledEvent:(KATGScheduledEvent *)scheduledEvent
{
	_scheduledEvent = scheduledEvent;
	self.timestamp = scheduledEvent.timestamp;
	NSString *subtitle = _scheduledEvent.subtitle;
    if([subtitle length] > 0)
        self.nextShowLabel.text = [NSString stringWithFormat:@"Featuring %@", subtitle];
    else
        self.nextShowLabel.text = @"";
	[self layoutLiveMode];
}

#pragma mark - 

- (void)refresh:(id)sender
{
	[self.liveShowDelegate liveShowRefreshButtonTapped:self];
}

- (void)endRefreshing
{
//	[self.refreshControl endRefreshing];
}

@end
