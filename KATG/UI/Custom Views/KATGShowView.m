//
//  KATGShowView.m
//  KATG
//
//  Created by Timothy Donnelly on 12/6/12.
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

#import "KATGShowView.h"
#import "KATGContentContainerView_Internal.h"
#import "TDRoundedShadowView.h"
#import "KATGButton.h"
#import "UIImageView+AFNetworking.h"

#define kKATGSideMargins 8.0f
#define kKATGColumnMargins 4.0f
#define kKATGShowNumberWidth 300.0f
#define kKATGCloseButtonWidth 60.0f

@implementation KATGShowView

- (void)configureWithShow:(KATGShow *)show
{
	self.showNumberLabel.text = [NSString stringWithFormat:@"EPISODE %@",show.number];
	self.showTitleLabel.text = show.title;

    NSArray *guests = [[show valueForKeyPath:@"Guests.name"] allObjects];
	self.showGuestsLabel.text = [guests componentsJoinedByString:@", "];
    self.guestLabel.hidden = [guests count] == 0;
    self.showGuestsLabel.hidden = [guests count] == 0;
	self.showTimeLabel.text = [show formattedTimestamp];
	
    for(UIView *v in [self.contentView subviews])
        if(v.tag == 111)
            [v removeFromSuperview];
    NSArray *images = [[show valueForKeyPath:@"Guests.picture_url"] allObjects];
    for(int i=0; i<[images count]; i++) {
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:
                                CGRectMake(16+i*56, 60, 50, 50)];
        [self.contentView addSubview:imgView];
        imgView.tag = 111;
        imgView.contentMode = UIViewContentModeScaleAspectFit;
        [imgView setImageWithURL:[NSURL URLWithString:images[i]]];
    }
	[self setNeedsLayout];
}

@end
