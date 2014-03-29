//
//  KATGEpisodesViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 27.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGEpisodesViewController.h"
#import "UIImageView+AFNetworking.h"

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
    
    [tableView registerNib:[UINib nibWithNibName:@"KATGShowCell" bundle:nil] forCellReuseIdentifier:@"kKATGShowCellIdentifier"];
    [tableView setContentInset:UIEdgeInsetsMake(-20, 0, 0, 0)];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateView];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:[[KATGDataStore sharedStore] readerContext]];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:[[KATGDataStore sharedStore] readerContext]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

-(void)setSeries:(KATGSeries *)value {
    _series = value;
    [self updateView];
}

-(IBAction)backAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)detailsAction:(id)sender {
    
}

-(void)updateView {
    [coverImage setImageWithURL:[NSURL URLWithString:_series.cover_image_url]];
    titleLabel.text = _series.title;
    [titleLabel sizeToFit];
    descLabel.text = _series.desc;
    int startNumber = [self.series.episode_number_max intValue] - 9;
    [[KATGDataStore sharedStore] downloadEpisodesForSeriesID:self.series.series_id
                                           fromEpisodeNumber:@(startNumber)];
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
    [tableView reloadData];
}

#pragma mark UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self.fetchedResultsController fetchedObjects] count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Loading cell for row %@", indexPath);
	KATGShowView *cell = [_tableView dequeueReusableCellWithIdentifier:@"kKATGShowCellIdentifier" forIndexPath:indexPath];
	[cell configureWithShow:[self.fetchedResultsController fetchedObjects][indexPath.row]];
	return cell;
}

-(CGFloat)tableView:(UITableView *)_tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Evaluating cell height for row %@", indexPath);
    KATGShow *show = [self.fetchedResultsController fetchedObjects][indexPath.row];
    NSArray *images = [[show valueForKeyPath:@"Guests.picture_url"] allObjects];
    if([images count] > 0)
        return 126;
    return 76;
}

-(void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    KATGShow *show = [self.fetchedResultsController fetchedObjects][indexPath.row];
    KATGShowViewController *showViewController = [[KATGShowViewController alloc] initWithNibName:@"KATGShowViewController" bundle:nil];
	showViewController.showObjectID = [show objectID];
	showViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:showViewController
                       animated:YES
                     completion:^{}];
}


@end
