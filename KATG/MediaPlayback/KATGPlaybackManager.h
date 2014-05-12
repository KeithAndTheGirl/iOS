//
//  KATGPlaybackManager.h
//  KATG
//
//  Created by Timothy Donnelly on 12/13/12.
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

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "KATGAudioPlayerController.h"

#define KATG_PLAYBACK_KEY @"KatgVip_key"
#define KATG_PLAYBACK_UID @"KatgVip_uid"

extern NSString *const KATGLiveShowStreamingServerOfflineNotification;

@class KATGShow, KATGAudioPlayerController;

@interface KATGPlaybackManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) KATGShow *currentShow;
- (void)configureWithShow:(KATGShow *)show;

- (void)configureForLiveShow;
- (bool)isLiveShow;

@property (nonatomic, readonly) CMTime duration;
@property (nonatomic, readonly) CMTime currentTime;
@property (nonatomic, readonly) NSArray *availableTime;
@property (nonatomic, readonly) KATGAudioPlayerState state;

- (void)seekToTime:(CMTime)currentTime;

- (void)play;
- (void)pause;

// forward or backward 15 seconds
- (void)jumpForward;
- (void)jumpBackward;

// jump an arbitrary amount of time
- (void)jump:(Float64)jump;

// Clears all state
- (void)stop;

-(NSError*)getCurrentError;

@end
