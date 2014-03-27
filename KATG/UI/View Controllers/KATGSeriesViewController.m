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

@implementation KATGSeriesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    collectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"SeriesBackground.png"]];
    [collectionView registerClass:[KATGSeriesCell class] forCellWithReuseIdentifier:@"series_cell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *seriesFetchRequest = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGSeries katg_entityName] inManagedObjectContext:[[KATGDataStore sharedStore] readerContext]];
	seriesFetchRequest.entity = entity;
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:KATGSeriesIDAttributeName ascending:YES];
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

#pragma mark NSFetchedResultsController
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [collectionView reloadData];
}


@end
