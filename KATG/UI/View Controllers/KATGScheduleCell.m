//
//  KATGScheduleCell.m
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

#import "KATGScheduleCell.h"
#import "KATGContentContainerView.h"
#import "KATGScheduleItemTableViewCell.h"

NSString *const kKATGScheduleItemTableViewCellIdentifier = @"kKATGScheduleItemTableViewCellIdentifier";

@interface KATGScheduleCell () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) KATGContentContainerView *containerView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UITableView *tableView;

@end

@implementation KATGScheduleCell

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		_tableView = [[UITableView alloc] initWithFrame:self.contentView.bounds style:UITableViewStylePlain];
		_tableView.allowsSelection = NO;
		_tableView.rowHeight = 64.0f;
		_tableView.separatorColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
		[_tableView registerClass:[KATGScheduleItemTableViewCell class] forCellReuseIdentifier:kKATGScheduleItemTableViewCellIdentifier];
		_tableView.backgroundColor = [UIColor clearColor];
		_tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:_tableView];
	}
	return self;
}

- (void)dealloc
{
	_tableView.delegate = nil;
	_tableView.dataSource = nil;
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	[self.tableView reloadData];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	self.containerView.frame = self.contentView.bounds;
}

@end
