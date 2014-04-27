//
//  KATGEpisodesViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 27.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGEpisodesViewController.h"
#import "UIImageView+AFNetworking.h"
#import "KATGShowViewController.h"
#import "KATGShow.h"
#import "KATGPlaybackManager.h"

@implementation KATGEpisodesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    backButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [backButton.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [backButton.layer setBorderWidth:0.5];
    [backButton.layer setCornerRadius:4];
    detailsButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [detailsButton.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [detailsButton.layer setBorderWidth:0.5];
    [detailsButton.layer setCornerRadius:4];
    
    tableView.backgroundView.backgroundColor = [UIColor blackColor];
    tableView.backgroundColor = [UIColor blackColor];
    [tableView registerNib:[UINib nibWithNibName:@"KATGShowCell" bundle:nil] forCellReuseIdentifier:@"kKATGShowCellIdentifier"];
    self.edgesForExtendedLayout = UIRectEdgeBottom;
    
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor whiteColor];
    [refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:refreshControl];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateView];
    [self reload];
    
    [self registerStateObserver];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[[KATGDataStore sharedStore] readerContext]];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self unregisterStateObserver];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:[[KATGDataStore sharedStore] readerContext]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

-(void)setSeries:(KATGSeries *)value {
    _series = value;
}

-(IBAction)backAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)detailsAction:(id)sender {
    
}

-(IBAction)settingsAction:(id)sender {
    KATGListSettingsController *settingsCtl = [[KATGListSettingsController alloc] init];
    settingsCtl.episodes = [self.fetchedResultsController fetchedObjects];
    [self presentViewController:settingsCtl animated:YES completion:nil];
}

-(void)updateView {
    spinner.hidden = YES;
    
    [coverImage setImageWithURL:[NSURL URLWithString:_series.cover_image_url]];
    titleLabel.text = _series.title;
    [titleLabel sizeToFit];
    descLabel.text = _series.desc;
    [self sortEpisodes];
    [tableView reloadData];
}

-(void)reload {
    if([self.sortedEpisodes count] == 0) {
        spinner.hidden = NO;
    }
    int startNumber = [self.series.episode_number_max intValue] - 9;
    [[KATGDataStore sharedStore] downloadEpisodesForSeriesID:self.series.series_id
                                           fromEpisodeNumber:@(startNumber)
                                                     success:^{
                                                         [refreshControl endRefreshing];
                                                     } failure:^{
                                                         [refreshControl endRefreshing];
                                                     }];
}

-(void)loadMore {
    if([self.series.episode_count intValue] > [self.sortedEpisodes count]) {
        UIActivityIndicatorView *moreSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        [tableView.tableFooterView addSubview:moreSpinner];
        moreSpinner.center = CGPointMake(160, 22);
        [moreSpinner startAnimating];
        
        KATGShow *lastShow = [self.sortedEpisodes lastObject];
        int startNumber = [lastShow.number intValue]-10;
        [[KATGDataStore sharedStore] downloadEpisodesForSeriesID:self.series.series_id
                                               fromEpisodeNumber:@(startNumber)
                                                         success:^{
                                                             tableView.tableFooterView = nil;
             
                                                         } failure:^{
                                                             tableView.tableFooterView = nil;
                                                         }];
    }
}

-(void)sortEpisodes {
    BOOL sortByRecentlyListened = [[NSUserDefaults standardUserDefaults] boolForKey:EPISODES_SORT_RECENTLY_LISTENED];
    BOOL filterDownloaded = [[NSUserDefaults standardUserDefaults] boolForKey:EPISODES_FILTER_DOWNLOADED];
    NSMutableArray *sourceArray = [NSMutableArray array];
    if(filterDownloaded) {
        for(KATGShow *show in [self.fetchedResultsController fetchedObjects])
            if(show.file_url)
                [sourceArray addObject:show];
    }
    else {
        [sourceArray addObjectsFromArray:[self.fetchedResultsController fetchedObjects]];
    }
    
    self.sortedEpisodes = [sourceArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSComparisonResult result;
        if(sortByRecentlyListened) {
            result = [[(KATGShow*)obj2 lastListenedTime] compare:[(KATGShow*)obj1 lastListenedTime]];
            if(result == NSOrderedSame)
                result = [[(KATGShow*)obj2 timestamp] compare:[(KATGShow*)obj1 timestamp]];
        }
        else {
            result = [[(KATGShow*)obj2 timestamp] compare:[(KATGShow*)obj1 timestamp]];
        }
        return result;
    }];
}

#pragma mark NSFetchedResultsController
- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *seriesFetchRequest = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGShow katg_entityName] inManagedObjectContext:[[KATGDataStore sharedStore] readerContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"series_id == %@", self.series.series_id];
    seriesFetchRequest.predicate = predicate;
	seriesFetchRequest.entity = entity;
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:KATGShowEpisodeIDAttributeName ascending:NO];
	seriesFetchRequest.sortDescriptors = [NSArray arrayWithObject:sort];
    
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:seriesFetchRequest managedObjectContext:[[KATGDataStore sharedStore] readerContext] sectionNameKeyPath:nil cacheName:@"Shows"];
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
	return _fetchedResultsController;
}

- (void)contextDidChange:(NSNotification *)note
{
	NSParameterAssert([NSThread isMainThread]);
	NSParameterAssert([note object] == [[KATGDataStore sharedStore] readerContext]);
    
    _fetchedResultsController = nil;
    [self updateView];
}

#pragma mark UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.sortedEpisodes count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	KATGShowView *cell = [_tableView dequeueReusableCellWithIdentifier:@"kKATGShowCellIdentifier" forIndexPath:indexPath];
	[cell configureWithShow:self.sortedEpisodes[indexPath.row]];
    
    if(indexPath.row == [self.sortedEpisodes count]-1) {
        [self loadMore];
    }
	return cell;
}

-(CGFloat)tableView:(UITableView *)_tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    KATGShow *show = self.sortedEpisodes[indexPath.row];
    NSArray *images = [[show valueForKeyPath:@"Guests.picture_url"] allObjects];
    if([images count] > 0)
        return 158;
    return 108;
}

-(void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    KATGShow *show = self.sortedEpisodes[indexPath.row];
    KATGShowViewController *showViewController = [[KATGShowViewController alloc] initWithNibName:@"KATGShowViewController" bundle:nil];
	showViewController.showObjectID = [show objectID];
    showViewController.needAuth = [self.series.vip_status boolValue];
	showViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:showViewController
                       animated:YES
                     completion:^{}];
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
		nowPlayingButton.frame = CGRectMake(0.0f, -28.0f, 320.0f, 48.0f);
		[nowPlayingButton addTarget:self action:@selector(showNowPlayingEpisode) forControlEvents:UIControlEventTouchUpInside];
        nowPlayingButton.tag = 1313;
        
        [tableView addSubview:nowPlayingButton];
        UIEdgeInsets contentInsets = tableView.contentInset;
        contentInsets.top += 48;
        tableView.contentInset = contentInsets;
        [tableView setContentOffset:CGPointMake(0, tableView.contentOffset.y-48) animated:NO];
	}
	else
	{
        UIView *v = [tableView viewWithTag:1313];
        if(v) {
            [v removeFromSuperview];
            UIEdgeInsets contentInsets = tableView.contentInset;
            contentInsets.top -= 48;
            tableView.contentInset = contentInsets;
        }
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
