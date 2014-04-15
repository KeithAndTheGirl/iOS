//
//  KATGScheduleViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 30.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGScheduleViewController.h"
#import "KATGScheduleItemTableViewCell.h"
#import "KATGDataStore.h"
#import "KATGScheduledEvent.h"
#import "KATGPlaybackManager.h"
#import "KATGShowViewController.h"
#import "KATGShow.h"

NSString *const kKATGScheduleItemTableViewCellIdentifier = @"kKATGScheduleItemTableViewCellIdentifier";

@implementation KATGScheduleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [tableView registerNib:[UINib nibWithNibName:@"KATGScheduleItemTableViewCell" bundle:nil] forCellReuseIdentifier:kKATGScheduleItemTableViewCellIdentifier];
    tableView.contentInset = tableView.scrollIndicatorInsets = UIEdgeInsetsMake(20, 0, 56, 0);
    [self registerStateObserver];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

#pragma mark NSFetchedResultsController
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[tableView reloadData];
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *seriesFetchRequest = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGScheduledEvent katg_entityName] inManagedObjectContext:[[KATGDataStore sharedStore] readerContext]];
	seriesFetchRequest.entity = entity;
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:KATGScheduledEventTimestampAttributeName ascending:YES];
	seriesFetchRequest.sortDescriptors = [NSArray arrayWithObject:sort];
    
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:seriesFetchRequest managedObjectContext:[[KATGDataStore sharedStore] readerContext] sectionNameKeyPath:nil cacheName:nil];
	aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
	return _fetchedResultsController;
}

#pragma mark UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self.fetchedResultsController fetchedObjects] count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	KATGScheduleItemTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:kKATGScheduleItemTableViewCellIdentifier forIndexPath:indexPath];
	KATGScheduledEvent *event = [self.fetchedResultsController fetchedObjects][indexPath.row];
	[cell configureWithScheduledEvent:event];
	cell.index = indexPath.row;
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 75;
}

#pragma mark GlobalPlayState
-(void)registerStateObserver {
    tableView.scrollsToTop = YES;
    [[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self configureTopBar];
}

-(void)unregisterStateObserver {
    tableView.scrollsToTop = NO;
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
