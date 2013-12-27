//
//  KATGForumCell.m
//  KATG
//
//  Created by Nicolas Rostov
//  Copyright (c) 2013 Doug Russell. All rights reserved.
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

#import "KATGForumCell.h"
#import "KATGButton.h"

@implementation KATGForumCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) 
	{
		self.showTopRule = YES;
		
		_forumButton = [KATGButton new];
		_forumButton.backgroundColor = [UIColor colorWithRed:243./255 green:245./255 blue:246./255 alpha:1];
        
		[_forumButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		_forumButton.titleLabel.shadowOffset = CGSizeMake(0.0f, 0.0f);
        _forumButton.imageEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 0);
        
        [_forumButton setTintColor:[UIColor blackColor]];
        _forumButton.titleLabel.textColor = [UIColor blackColor];
		[_forumButton addTarget:self action:@selector(forumButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

		[self.forumButton setImage:[UIImage imageNamed:@"comments.png"] forState:UIControlStateNormal];
        [self.forumButton setTitle:@"Comments & Discussions" forState:UIControlStateNormal];
        
		[self.contentView addSubview:self.forumButton];
	}
	return self;
}

- (void)prepareForReuse
{
	[super prepareForReuse];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	self.forumButton.frame = CGRectMake(50.0f, 10.0f, self.contentView.bounds.size.width - 100.0f, self.contentView.bounds.size.height - 20.0f);
}

- (void)forumButtonPressed:(id)sender
{
	[self.delegate forumButtonPressed:self];
}

@end
