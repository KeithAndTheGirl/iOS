//
//  KATGLiveViewController.h
//  KATG
//
//  Created by Nicolas Rostov on 29.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KATGAudioPlayerController.h"
#import "KATGScheduledEvent.h"

@class KATGButton, KATG_TimerTarget, KATGControlButton;

@interface KATGLiveViewController : UIViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic) bool liveMode;
@property (nonatomic) KATGAudioPlayerState currentAudioPlayerState;
@property (nonatomic) NSDate *timestamp;
@property (strong, nonatomic) KATGScheduledEvent *scheduledEvent;

@property (nonatomic) IBOutlet UIView *internalView;
@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UILabel *nextShowLabel;
@property (nonatomic) IBOutlet UIView *timerSection;
@property (nonatomic) IBOutlet UILabel *countLabelHours;
@property (nonatomic) IBOutlet UILabel *countLabelMinutes;
@property (nonatomic) IBOutlet UILabel *countLabelSeconds;
@property (nonatomic) IBOutlet UILabel *onAirLabel;
@property (nonatomic) IBOutlet UILabel *descriptionLabel;

@property (nonatomic) IBOutlet UIButton *feedbackButton;
@property (nonatomic) KATG_TimerTarget *target;
@property (nonatomic) NSTimer *timer;

@property (nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@property (nonatomic) IBOutlet UIButton *liveToggleButton;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;


- (void)addObservers;
- (void)removeObservers;
- (void)updateViewState;
- (IBAction)playButtonTapped:(id)sender;
- (IBAction)toggleLive:(id)sender;
- (IBAction)sendFeedbackButtonPressed:(id)sender;

- (void)setLiveMode:(bool)liveMode animated:(BOOL)animated;

@end
