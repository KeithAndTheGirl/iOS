//
//  KATGSeriesViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 26.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGSeriesViewController.h"
#import "KATGDataStore.h"
#import "KATGSeries.h"
#import "KATGSeriesCell.h"
#import "KATGEpisodesViewController.h"
#import "KATGShowViewController.h"
#import "KATGShow.h"
#import "KATGPlaybackManager.h"

@implementation KATGSeriesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    collectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"SeriesBackground.png"]];
    [collectionView registerClass:[KATGSeriesCell class] forCellWithReuseIdentifier:@"series_cell"];
    [self registerStateObserver];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

#pragma mark NSFetchedResultsController
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [collectionView reloadData];
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *seriesFetchRequest = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGSeries katg_entityName] inManagedObjectContext:[[KATGDataStore sharedStore] readerContext]];
	seriesFetchRequest.entity = entity;
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:KATGSeriesSortAttributeName ascending:YES];
	seriesFetchRequest.sortDescriptors = [NSArray arrayWithObject:sort];
    
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:seriesFetchRequest managedObjectContext:[[KATGDataStore sharedStore] readerContext] sectionNameKeyPath:nil cacheName:@"Series"];
	aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
	return _fetchedResultsController;
}

#pragma mark - UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self.fetchedResultsController fetchedObjects] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)_collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    KATGSeries *series = [self.fetchedResultsController fetchedObjects][indexPath.row];
	KATGSeriesCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:@"series_cell" forIndexPath:indexPath];
    cell.object = series;
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [KATGSeriesCell cellSize];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	return [KATGSeriesCell lineSpacing];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    KATGEpisodesViewController *episodesController = [[KATGEpisodesViewController alloc] init];
    KATGSeries *series = [self.fetchedResultsController fetchedObjects][indexPath.row];
    episodesController.series = series;
    [self.navigationController pushViewController:episodesController animated:YES];
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
        
        [collectionView addSubview:nowPlayingButton];
        UIEdgeInsets contentInsets = collectionView.contentInset;
        contentInsets.top += 48;
        collectionView.contentInset = contentInsets;
        [collectionView setContentOffset:CGPointMake(0, collectionView.contentOffset.y-48) animated:NO];
	}
	else
	{
        UIView *v = [collectionView viewWithTag:1313];
        if(v) {
            [v removeFromSuperview];
            UIEdgeInsets contentInsets = collectionView.contentInset;
            contentInsets.top -= 48;
            collectionView.contentInset = contentInsets;
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
