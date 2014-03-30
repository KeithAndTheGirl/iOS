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
#import "KATGDataStore.h"
#import "KATGPlaybackManager.h"

NSString *const kkKATGScheduleItemTableViewCellIdentifier = @"kKATGScheduleItemTableViewCellIdentifier";

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
//		[_tableView registerClass:[KATGScheduleItemTableViewCell class] forCellReuseIdentifier:kKATGScheduleItemTableViewCellIdentifier];
        [_tableView registerNib:[UINib nibWithNibName:@"KATGScheduleItemTableViewCell" bundle:nil] forCellReuseIdentifier:kKATGScheduleItemTableViewCellIdentifier];
		_tableView.backgroundColor = [UIColor clearColor];
		_tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _tableView.scrollsToTop = NO;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.) {
            _tableView.contentInset = UIEdgeInsetsMake(20, 0, 56, 0);
            _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(20, 0, 56, 0);
        }
        else {
            _tableView.contentInset = UIEdgeInsetsMake(0, 0, 56, 0);
            _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 56, 0);
        }
		[self.contentView addSubview:_tableView];
        
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
        [_tableView addSubview:self.refreshControl];
	}
	return self;
}

-(void)refreshTable {
    [[KATGDataStore sharedStore] downloadEvents];
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

-(void)willShow {
    [self.refreshControl endRefreshing];
    _tableView.scrollsToTop = YES;
    [[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self configureNavBar];
}

-(void)willHide {
    _tableView.scrollsToTop = NO;
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:@"state"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self configureNavBar];
}

- (void)configureNavBar
{
	if ([[KATGPlaybackManager sharedManager] currentShow] &&
        [[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying)
	{
		UIButton *nowPlayingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nowPlayingButton setImage:[UIImage imageNamed:@"NowPlaying.png"] forState:UIControlStateNormal];
		nowPlayingButton.frame = CGRectMake(0.0f, -48.0f, 320.0f, 48.0f);
		[nowPlayingButton addTarget:self.controller action:@selector(nowPlaying:) forControlEvents:UIControlEventTouchUpInside];
        nowPlayingButton.tag = 1313;
        
        _tableView.tableHeaderView = nowPlayingButton;
	}
	else
	{
        _tableView.tableHeaderView = nil;
	}
}

@end
