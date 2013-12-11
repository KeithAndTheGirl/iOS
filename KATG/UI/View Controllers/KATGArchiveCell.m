//
//  KATGArchiveCell.m
//  KATG
//
//  Created by Timothy Donnelly on 11/12/12.
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

#import "KATGArchiveCell.h"
#import "KATGShow.h"
#import "KATGGuest.h"
#import "KATGShowView.h"
#import "TDRoundedShadowView.h"
#import "KATGButton.h"

NSString *const kKATGShowCellIdentifier = @"kKATGShowCellIdentifier";

@interface KATGArchiveCell ()
@end

@implementation KATGArchiveCell

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		_tableView = [[UITableView alloc] initWithFrame:self.contentView.bounds style:UITableViewStylePlain];
		_tableView.allowsSelection = YES;
		_tableView.rowHeight = 120.0f;
		_tableView.separatorColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
        [_tableView registerNib:[UINib nibWithNibName:@"KATGShowCell" bundle:nil] forCellReuseIdentifier:kKATGShowCellIdentifier];
		_tableView.backgroundColor = [UIColor clearColor];
		_tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, 56, 0);
        _tableView.scrollIndicatorInsets = _tableView.contentInset;
		[self.contentView addSubview:_tableView];
	}
	return self;
}

- (void)dealloc
{
	_tableView.delegate = nil;
	_tableView.dataSource = nil;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	[self.tableView reloadData];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.shows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	KATGShowView *cell = [tableView dequeueReusableCellWithIdentifier:kKATGShowCellIdentifier forIndexPath:indexPath];
	[cell configureWithShow:self.shows[indexPath.row]];
	return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    KATGShow *show = self.shows[indexPath.row];
    NSArray *images = [[show valueForKeyPath:@"Guests.picture_url"] allObjects];
    if([images count] > 0)
        return 116;
    return 68;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.controller presentShow:self.shows[indexPath.row] fromArchiveCell:self];
}

@end