//
//  KATGYoutubeCell.m
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

#import "KATGYoutubeCell.h"
#import "KATGContentContainerView.h"
#import "KATGYouTubeTableCell.h"
#import "AFNetworking.h"
#import <MediaPlayer/MediaPlayer.h>
#import "KATGYouTubeViewController.h"

NSString *const kKATGYoutubeTableViewCellIdentifier = @"KATGYouTubeTableCell";

@interface KATGYoutubeCell () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *channelItems;

@end

@implementation KATGYoutubeCell

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		_tableView = [[UITableView alloc] initWithFrame:self.contentView.bounds style:UITableViewStylePlain];
		_tableView.allowsSelection = YES;
		_tableView.rowHeight = 66.0f;
		_tableView.separatorColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
		[_tableView registerNib:[UINib nibWithNibName:@"KATGYouTubeTableCell" bundle:nil]
         forCellReuseIdentifier:kKATGYoutubeTableViewCellIdentifier];
		_tableView.backgroundColor = [UIColor clearColor];
		_tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        
        if([_tableView canPerformAction:@selector(setSeparatorInset:) withSender:self]) {
            _tableView.separatorInset = UIEdgeInsetsZero;
        }
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.) {
            _tableView.contentInset = UIEdgeInsetsMake(20, 0, 56, 0);
            _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(20, 0, 56, 0);
        }
        else {
            _tableView.contentInset = UIEdgeInsetsMake(0, 0, 56, 0);
            _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 56, 0);
        }
		[self.contentView addSubview:_tableView];
        
        _spinnerView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        _spinnerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
        UIActivityIndicatorView *actView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        actView.center = CGPointMake(self.contentView.frame.size.width/3, self.contentView.frame.size.height/2);
        [actView startAnimating];
        [_spinnerView addSubview:actView];
        
        UILabel *actLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width/2.5, self.contentView.frame.size.height/2-12, 120, 24)];
        actLabel.text = @"Loading...";
        actLabel.textColor = [UIColor whiteColor];
        [_spinnerView addSubview:actLabel];
        [self.contentView addSubview:_spinnerView];
        _spinnerView.hidden = YES;
        
        [self reload];
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
    NSDate *lastUpdate = [[NSUserDefaults standardUserDefaults] valueForKey:@"ytLastUpdate"];
    if(!lastUpdate || [self.channelItems count]==0 || fabs([lastUpdate timeIntervalSinceNow]) > 5*60) {
        [self reload];
    }
}

- (void)layoutSubviews
{
	[super layoutSubviews];
}

// gdata.youtube.com/feeds/api/users/keithandthegirl/uploads?&v=2&max-results=50&alt=jsonc
-(void)reload {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        _spinnerView.hidden = [self.channelItems count] > 0;
	});
    NSDictionary *parameters = @{@"v": @"2",
                                 @"max-results": @"50",
                                 @"alt": @"jsonc"};
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://gdata.youtube.com"]];
    [manager GET:@"feeds/api/users/keithandthegirl/uploads"
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             self.channelItems = responseObject[@"data"][@"items"];
             [self.tableView reloadData];
             _spinnerView.hidden = YES;
             [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"ytLastUpdate"];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"%@", [error description]);
             if([self.hostController respondsToSelector:@selector(connectivityFailed)])
                 [self.hostController performSelector:@selector(connectivityFailed) withObject:nil];
             _spinnerView.hidden = YES;
         }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.channelItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	KATGYouTubeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:kKATGYoutubeTableViewCellIdentifier forIndexPath:indexPath];
	[cell configureWithDictionary:self.channelItems[indexPath.row]];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *item = self.channelItems[indexPath.row];
    KATGYouTubeViewController *youtubeController = [[KATGYouTubeViewController alloc] init];
    youtubeController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
     [self.hostController presentViewController:youtubeController animated:YES completion:^{
         
     }];
    
        youtubeController.dataDictionary = item;
}


@end
