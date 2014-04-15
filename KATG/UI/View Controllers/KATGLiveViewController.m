//
//  KATGLiveViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 29.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGLiveViewController.h"
#import "KATGPlaybackManager.h"
#import "KATGDataStore.h"
#import "KATGScheduledEvent.h"
#import "KATGLiveShowFeedbackViewController.h"
#import "KATGShowViewController.h"
#import "KATGShow.h"

@interface KATG_TimerTarget : NSProxy
@property (weak, nonatomic) id target;
@end
@implementation KATG_TimerTarget
- (id)forwardingTargetForSelector:(SEL)aSelector
{
	id target = self.target;
	NSAssert(target, @"Timer target has gone to nil. This will crash and is probably caused by not cleaning up the timer associated with this target.");
	return target;
}
@end


static void * KATGIsLiveObserverContext = @"IsLiveObserverContext";

@implementation KATGLiveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    _target = [KATG_TimerTarget alloc];
    _target.target = self;
    
    _timer = [NSTimer timerWithTimeInterval:1.0f target:_target selector:@selector(updateCounter) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
    [self addObservers];
	[self updateViewState];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)dealloc
{
	[_timer invalidate];
	[self removeObservers];
}

- (void)updateViewState {
    KATGScheduledEvent *event = [self.fetchedResultsController fetchedObjects][0];
    [self setScheduledEvent:event];
    [self setLiveMode:[[KATGDataStore sharedStore] isShowLive]];
}

#pragma mark NSFetchedResultsController
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self updateViewState];
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *seriesFetchRequest = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGScheduledEvent katg_entityName] inManagedObjectContext:[[KATGDataStore sharedStore] readerContext]];
	seriesFetchRequest.entity = entity;
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:KATGScheduledEventTimestampAttributeName ascending:YES];
	seriesFetchRequest.sortDescriptors = [NSArray arrayWithObject:sort];
    
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:seriesFetchRequest managedObjectContext:[[KATGDataStore sharedStore] readerContext] sectionNameKeyPath:nil cacheName:nil];
	aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
	return _fetchedResultsController;
}

- (void)addObservers
{
	[[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:KATGStateObserverKey options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
	[[KATGDataStore sharedStore] addObserver:self forKeyPath:kKATGDataStoreIsShowLiveKey options:0 context:KATGIsLiveObserverContext];
}

- (void)removeObservers
{
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:KATGStateObserverKey];
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:kKATGDataStoreIsShowLiveKey context:KATGIsLiveObserverContext];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == KATGIsLiveObserverContext)
	{
        [self updateViewState];
	}
	else if ([keyPath isEqualToString:KATGStateObserverKey])
	{
		if ([[KATGPlaybackManager sharedManager] isLiveShow])
		{
			CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
				self.currentAudioPlayerState = [[KATGPlaybackManager sharedManager] state];
			});
		}
        else {
            [self configureTopBar];
        }
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -
- (IBAction)sendFeedbackButtonPressed:(id)sender
{
    UIViewController *controller = [[KATGLiveShowFeedbackViewController alloc] initWithNibName:@"KATGLiveShowFeedbackViewController" bundle:nil];
    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		controller.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[self presentViewController:controller animated:YES completion:NULL];
}

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
	self.countLabelHours.text = [NSString stringWithFormat:@"%d", (int)components.hour];
	self.countLabelMinutes.text = [NSString stringWithFormat:@"%02d", (int)components.minute];
	self.countLabelSeconds.text = [NSString stringWithFormat:@"%02d", (int)components.second];
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
- (void)configureTopBar
{
	if ([[KATGPlaybackManager sharedManager] currentShow] &&
        [[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying)
	{
		UIView *v = [self.view viewWithTag:1313];
        if(!v) {
            UIButton *nowPlayingButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [nowPlayingButton setImage:[UIImage imageNamed:@"NowPlaying.png"] forState:UIControlStateNormal];
            nowPlayingButton.frame = CGRectMake(0.0f, 20.0f, 320.0f, 48.0f);
            [nowPlayingButton addTarget:self action:@selector(showNowPlayingEpisode) forControlEvents:UIControlEventTouchUpInside];
            nowPlayingButton.tag = 1313;
            
            [self.view addSubview:nowPlayingButton];
        }
	}
	else
	{
        UIView *v = [self.view viewWithTag:1313];
        if(v) {
            [v removeFromSuperview];
        }
	}
}

-(void)showNowPlayingEpisode {
    KATGShow *show = [[KATGPlaybackManager sharedManager] currentShow];
    KATGShowViewController *showViewController = [[KATGShowViewController alloc] initWithNibName:@"KATGShowViewController" bundle:nil];
	showViewController.showObjectID = [show objectID];
	showViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:showViewController animated:YES completion:nil];
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
    
    UITabBar *tabBar = self.tabBarController.tabBar;
    if(liveMode) {
        if(![tabBar viewWithTag:111]) {
            UIView *redView = [[UIView alloc]initWithFrame:CGRectMake(64+42, 4, 6, 6)];
            redView.tag = 111;
            [redView.layer setBorderColor:[[UIColor redColor] CGColor]];
            [redView.layer setCornerRadius:4];
            [redView.layer setBorderWidth:4];
            redView.backgroundColor = [UIColor redColor];
            [tabBar addSubview:redView];
        }
    }
    else {
        [[tabBar viewWithTag:111] removeFromSuperview];
    }
}

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
        [[KATGPlaybackManager sharedManager] stop];
		[[KATGPlaybackManager sharedManager] configureForLiveShow];
		[[KATGPlaybackManager sharedManager] play];
	}
}

-(void)updatePlayerState {
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
    [self performSelector:@selector(updatePlayerState) withObject:nil afterDelay:0.2];
}

@end
