//
//  KATGYoutubeViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 30.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGYoutubeViewController.h"
#import "KATGYoutubeDetails.h"
#import "KATGYouTubeTableCell.h"
#import "AFNetworking.h"
#import "KATGPlaybackManager.h"
#import "KATGShowViewController.h"
#import "KATGShow.h"

NSString *const kKATGYoutubeTableViewCellIdentifier = @"KATGYouTubeTableCell";

@implementation KATGYoutubeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [tableView registerNib:[UINib nibWithNibName:@"KATGYouTubeTableCell" bundle:nil]
     forCellReuseIdentifier:kKATGYoutubeTableViewCellIdentifier];
    
     refreshControl = [[UIRefreshControl alloc] init];
     [refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
     [tableView addSubview:refreshControl];
    
    [self reload];
    [self registerStateObserver];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mak logic
// gdata.youtube.com/feeds/api/users/keithandthegirl/uploads?&v=2&max-results=50&alt=jsonc
-(void)reload {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        spinnerView.hidden = [channelItems count] > 0;
	});
    NSDictionary *parameters = @{@"v": @"2",
                                 @"max-results": @"50",
                                 @"alt": @"jsonc"};
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://gdata.youtube.com"]];
    [manager GET:@"feeds/api/users/keithandthegirl/uploads"
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             channelItems = responseObject[@"data"][@"items"];
             [tableView reloadData];
             spinnerView.hidden = YES;
             [refreshControl endRefreshing];
             [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"ytLastUpdate"];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"%@", [error description]);
//             if([controller respondsToSelector:@selector(connectivityFailed)])
//                 [self.controller performSelector:@selector(connectivityFailed) withObject:nil];
             spinnerView.hidden = YES;
             [refreshControl endRefreshing];
         }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [channelItems count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	KATGYouTubeTableCell *cell = [_tableView dequeueReusableCellWithIdentifier:kKATGYoutubeTableViewCellIdentifier forIndexPath:indexPath];
	[cell configureWithDictionary:channelItems[indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 66;
}

-(void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *item = channelItems[indexPath.row];
    KATGYoutubeDetails *youtubeDetails = [[KATGYoutubeDetails alloc] init];
    [self.navigationController pushViewController:youtubeDetails animated:YES];
    youtubeDetails.dataDictionary = item;
}

#pragma mark GlobalPlayState
-(void)registerStateObserver {
    [[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self configureTopBar];
}

-(void)unregisterStateObserver {
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:@"state"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self configureTopBar];
}

- (void)configureTopBar
{
	if ([[KATGPlaybackManager sharedManager] currentShow] &&
        [[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying)
	{
		UIButton *nowPlayingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nowPlayingButton setImage:[UIImage imageNamed:@"NowPlaying.png"] forState:UIControlStateNormal];
		nowPlayingButton.frame = CGRectMake(0.0f, -48.0f, 320.0f, 48.0f);
		[nowPlayingButton addTarget:self action:@selector(showNowPlayingEpisode) forControlEvents:UIControlEventTouchUpInside];
        nowPlayingButton.tag = 1313;
        
        tableView.tableHeaderView = nowPlayingButton;
	}
	else
	{
        tableView.tableHeaderView = nil;
	}
}

-(void)showNowPlayingEpisode {
    KATGShow *show = [[KATGPlaybackManager sharedManager] currentShow];
    KATGShowViewController *showViewController = [[KATGShowViewController alloc] initWithNibName:@"KATGShowViewController" bundle:nil];
	showViewController.showObjectID = [show objectID];
	showViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:showViewController animated:YES completion:nil];
}

@end
