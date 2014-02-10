//
//  KATGLiveCell.h
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

#import <UIKit/UIKit.h>
#import "KATGAudioPlayerController.h"
#import "KATGScheduledEvent.h"

@class KATGButton, KATGTimerTarget, KATGControlButton;

@protocol KATGLiveCellDelegate;

@interface KATGLiveCell : UICollectionViewCell

@property (nonatomic) bool liveMode;
@property (nonatomic) KATGAudioPlayerState currentAudioPlayerState;
@property (nonatomic) NSDate *timestamp;
@property (strong, nonatomic) KATGScheduledEvent *scheduledEvent;
@property (weak, nonatomic) id<KATGLiveCellDelegate> liveShowDelegate;

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
@property (nonatomic) KATGTimerTarget *target;
@property (nonatomic) NSTimer *timer;

@property (nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@property (nonatomic) IBOutlet UIButton *liveToggleButton;

- (IBAction)playButtonTapped:(id)sender;
- (IBAction)toggleLive:(id)sender;
- (IBAction)sendFeedbackButtonPressed:(id)sender;

- (void)setLiveMode:(bool)liveMode animated:(BOOL)animated;
- (void)endRefreshing;

-(void)willShow;
-(void)willHide;

@end

@protocol KATGLiveCellDelegate <NSObject>

- (void)liveShowFeedbackButtonTapped:(KATGLiveCell *)cell;
- (void)liveShowRefreshButtonTapped:(KATGLiveCell *)cell;

@end