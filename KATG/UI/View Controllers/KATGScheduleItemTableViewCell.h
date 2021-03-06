//
//  KATGScheduleItemTableViewCell.h
//  KATG
//
//  Created by Timothy Donnelly on 12/12/12.
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

@class KATGScheduledEvent;

@protocol KATGScheduleItemTableViewCellDelegate;

@interface KATGScheduleItemTableViewCell : UITableViewCell

@property (nonatomic)IBOutlet UILabel *episodeNameLabel;
@property (nonatomic)IBOutlet UILabel *episodeGuestLabel;
@property (nonatomic)IBOutlet UILabel *episodeGuestLabelCaption;
@property (nonatomic)IBOutlet UILabel *episodeDateLabel;
@property (nonatomic)IBOutlet UILabel *episodeTimeLabel;

@property (weak, nonatomic) id<KATGScheduleItemTableViewCellDelegate> longPressDelegate;
@property (nonatomic) NSUInteger index;

- (void)configureWithScheduledEvent:(KATGScheduledEvent *)scheduledEvent;

@end

@protocol KATGScheduleItemTableViewCellDelegate <NSObject>
- (void)longPressAction:(KATGScheduleItemTableViewCell *)cell;
@end
