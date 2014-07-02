//
//  KATGScheduleItemTableViewCell.m
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

#import "KATGScheduleItemTableViewCell.h"
#import "KATGScheduledEvent.h"
#import "TDRoundedShadowView.h"

#define kKATGScheduleItemSideMargin 14.0f

@implementation KATGScheduleItemTableViewCell


- (void)longPressed:(UILongPressGestureRecognizer *)sender
{
	if ([sender state] == UIGestureRecognizerStateRecognized)
	{
		[self.longPressDelegate longPressAction:self];
	}
}

- (void)configureWithScheduledEvent:(KATGScheduledEvent *)scheduledEvent
{
	self.episodeNameLabel.text = [scheduledEvent.title uppercaseString];
    NSString *guests = [scheduledEvent.subtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if([guests length]) {
        self.episodeGuestLabelCaption.hidden = NO;
        self.episodeGuestLabel.text = guests;
    }
    else {
        self.episodeGuestLabelCaption.hidden = YES;
        self.episodeGuestLabel.text = @"";
    }
    
	self.episodeDateLabel.text = [scheduledEvent formattedDate];
	self.episodeTimeLabel.text = [scheduledEvent formattedTime];
}

@end
