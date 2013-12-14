//
//  KATGAboutCell.m
//  KATG
//
//  Created by Nicolas Rostov on 12/9/13.
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

#import "KATGAboutCell.h"
#import "KATGContentContainerView.h"
#import "KATGScheduleItemTableViewCell.h"

NSString *const kKATGAboutTableViewCellIdentifier = @"kKATGAboutTableViewCellIdentifier";

@interface KATGAboutCell () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UITableView *tableView;

@end

@implementation KATGAboutCell

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		_tableView = [[UITableView alloc] initWithFrame:self.contentView.bounds style:UITableViewStylePlain];
		_tableView.allowsSelection = NO;
		_tableView.rowHeight = 64.0f;
		_tableView.separatorColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
		[_tableView registerClass:[KATGScheduleItemTableViewCell class] forCellReuseIdentifier:kKATGAboutTableViewCellIdentifier];
		_tableView.backgroundColor = [UIColor clearColor];
		_tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.) {
            _tableView.contentInset = UIEdgeInsetsMake(20, 0, 56, 0);
            _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(20, 0, 56, 0);
        }
        else {
            _tableView.contentInset = UIEdgeInsetsMake(0, 0, 56, 0);
            _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 56, 0);
        }
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
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 15;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kKATGAboutTableViewCellIdentifier forIndexPath:indexPath];
	cell.textLabel.text = @"About cell";
	return cell;
}


@end
