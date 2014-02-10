//
//  KATGMainDataSource.m
//  KATG
//
//  Created by Doug Russell on 4/16/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
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

#import "KATGMainDataSource.h"

#import "KATGMainResultsController.h"
#import "KATGTabBar.h"

#import "TDCollectionView.h"
#import "UICollectionView+TDAdditions.h"

#import "KATGArchiveCell.h"
#import "KATGScheduleCell.h"
#import "KATGSHowView.h"
#import "KATGLiveCell.h"
#import "KATGYoutubeCell.h"
#import "KATGAboutCell.h"

#import "KATGScheduledEvent.h"

#import "KATGScheduleItemTableViewCell.h"

#import "KATGDataStore.h"

static CGFloat const kKATGCollectionViewColumnMargin = 0;
static NSString *const kKATGScheduleCellIdentifier = @"kKATGScheduleCellIdentifier";
static NSString *const kKATGLiveCellIdentifier = @"kKATGLiveCellIdentifier";
static NSString *const kKATGArchiveCellIdentifier = @"kKATGArchiveCellIdentifier";
static NSString *const kKATGYoutubeCellIdentifier = @"kKATGYoutubeCellIdentifier";
static NSString *const kKATGAboutCellIdentifier = @"kKATGAboutCellIdentifier";

@interface KATGMainDataSource () <KATGMainResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) KATGMainResultsController *resultsController;

// Track the target scroll position between UIScrollViewDelegate methods
@property (nonatomic) CGPoint currentScrollTargetOffset;
@property (nonatomic) CGPoint currentScrollBeginningOffset;
@property (nonatomic) KATGSection currentScrollBeginningSection;

@end

@implementation KATGMainDataSource

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		_resultsController = [KATGMainResultsController new];
		_resultsController.delegate = self;
	}
	return self;
}

- (void)dealloc
{
	_mainCollectionView.dataSource = nil;
	_mainCollectionView.delegate = nil;
	_eventsTableView.dataSource = nil;
	_eventsTableView.delegate = nil;
}

#pragma mark - Public API

- (NSArray *)shows
{
	return self.resultsController.shows;
}

- (NSArray *)events
{
	return self.resultsController.events;
}

- (bool)performFetch:(NSError *__autoreleasing*)error
{
	if ([self.resultsController performFetch:error])
	{
		[self reloadData];
		return true;
	}
	return false;
}

#pragma mark - 

- (void)reloadData
{
	NSParameterAssert([NSThread isMainThread]);
	//NSLog(@"Reload Data");
	self.eventsTableView = nil;
	[self.mainCollectionView reloadData];
}

#pragma mark - Main Collection View

- (void)setMainCollectionView:(TDCollectionView *)mainCollectionView
{
	if (_mainCollectionView != mainCollectionView)
	{
		_mainCollectionView.dataSource = nil;
		_mainCollectionView.delegate = nil;
		_mainCollectionView = mainCollectionView;
		_mainCollectionView.dataSource = self;
		_mainCollectionView.delegate = self;
		
		[_mainCollectionView registerClass:[KATGScheduleCell class] forCellWithReuseIdentifier:kKATGScheduleCellIdentifier];
//		[_mainCollectionView registerClass:[KATGLiveCell class] forCellWithReuseIdentifier:kKATGLiveCellIdentifier];
        [_mainCollectionView registerNib:[UINib nibWithNibName:@"KATGLiveCell" bundle:nil]
              forCellWithReuseIdentifier:kKATGLiveCellIdentifier];
		[_mainCollectionView registerClass:[KATGArchiveCell class] forCellWithReuseIdentifier:kKATGArchiveCellIdentifier];
		[_mainCollectionView registerClass:[KATGYoutubeCell class] forCellWithReuseIdentifier:kKATGYoutubeCellIdentifier];
//		[_mainCollectionView registerClass:[KATGAboutCell class] forCellWithReuseIdentifier:kKATGAboutCellIdentifier];
        [_mainCollectionView registerNib:[UINib nibWithNibName:@"KATGAboutCell" bundle:nil] forCellWithReuseIdentifier:kKATGAboutCellIdentifier];
	}
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 5;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	switch ((KATGSection)section)
	{
		case KATGSectionSchedule:
		case KATGSectionLive:
		case KATGSectionArchive:
        case KATGSectionYoutube:
        case KATGSectionAbout:
            return 1;
		default:
			return 0;
	}
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    [(KATGScheduleCell*)self.lastScrollablaCell willHide];
	UICollectionViewCell *cell = nil;
	switch ((KATGSection)indexPath.section)
	{
		case KATGSectionSchedule:
			cell = [collectionView dequeueReusableCellWithReuseIdentifier:kKATGScheduleCellIdentifier forIndexPath:indexPath];
			self.eventsTableView = ((KATGScheduleCell *)cell).tableView;
            [(KATGScheduleCell*)cell willShow];
            self.lastScrollablaCell = cell;
			break;
		case KATGSectionLive:
			cell = [collectionView dequeueReusableCellWithReuseIdentifier:kKATGLiveCellIdentifier forIndexPath:indexPath];
			[self configureLiveCell:(KATGLiveCell *)cell animated:NO];
            [(KATGLiveCell*)cell willShow];
            self.lastScrollablaCell = cell;
			break;
		case KATGSectionArchive:
		{
			KATGArchiveCell *archiveCell = [collectionView dequeueReusableCellWithReuseIdentifier:kKATGArchiveCellIdentifier forIndexPath:indexPath];
//			KATGShow *show = self.resultsController.shows[indexPath.item];
			archiveCell.shows = self.resultsController.shows;
            archiveCell.controller = self.mainViewController;
//			archiveCell.showView.footerHeight = 120.0f - archiveCell.showView.headerHeight;
			cell = archiveCell;
            [archiveCell willShow];
            self.lastScrollablaCell = cell;
            
            [self.mainViewController performSelector:@selector(configureNavBar) withObject:nil afterDelay:0.5];
			break;
		}
        case KATGSectionYoutube:
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:kKATGYoutubeCellIdentifier forIndexPath:indexPath];
            ((KATGYoutubeCell*)cell).hostController = self.mainViewController;
            [(KATGYoutubeCell*)cell willShow];
            self.lastScrollablaCell = cell;
			break;
        case KATGSectionAbout:
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:kKATGAboutCellIdentifier forIndexPath:indexPath];
            [(KATGAboutCell*)cell willShow];
            self.lastScrollablaCell = cell;
			break;
	}
	return cell;
}

- (void)configureLiveCell:(KATGLiveCell *)liveCell animated:(BOOL)animated
{
	KATGScheduledEvent *event = nil;
	if ([self.events count])
		event = self.events[0];
	liveCell.scheduledEvent = event;
	liveCell.liveShowDelegate = self.mainViewController;
	[liveCell setLiveMode:[[KATGDataStore sharedStore] isShowLive] animated:animated];
	[liveCell endRefreshing];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	CGSize cellSize;
	switch ((KATGSection)indexPath.section)
	{
		case KATGSectionYoutube:
		case KATGSectionAbout:
		case KATGSectionSchedule:
		case KATGSectionArchive:
		case KATGSectionLive:
            cellSize = self.mainViewController.view.frame.size;
			break;
		default:
			NSParameterAssert(NO);
			break;
	}
	return cellSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
	switch ((KATGSection)section)
	{
        case KATGSectionAbout:
		case KATGSectionYoutube:
		case KATGSectionSchedule:
		case KATGSectionArchive:
		case KATGSectionLive:
            return UIEdgeInsetsMake(-20, 0, 0, 0);
		default:
			NSParameterAssert(NO);
			return UIEdgeInsetsZero;
	}
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    switch ((KATGSection)indexPath.section)
	{
		case KATGSectionSchedule:
			self.eventsTableView = nil;
			break;
		case KATGSectionArchive:
		case KATGSectionLive:
		case KATGSectionYoutube:
		case KATGSectionAbout:
			break;
	}
}

#pragma mark - Results

- (void)reloadAllData
{
	[self reloadData];
}

- (void)didChangeEvents
{
	NSParameterAssert([NSThread isMainThread]);
	[self.eventsTableView reloadData];
	NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:KATGSectionLive];
	if ([[self.mainCollectionView indexPathsForVisibleItems] containsObject:indexPath])
	{
		KATGLiveCell *cell = (KATGLiveCell *)[self.mainCollectionView cellForItemAtIndexPath:indexPath];
		if (cell)
		{
			[self configureLiveCell:cell animated:YES];
		}
	}
}

- (void)didChangeShows
{
	NSParameterAssert([NSThread isMainThread]);
	[self.mainCollectionView reloadSections:[NSIndexSet indexSetWithIndex:KATGSectionArchive]];
}

#pragma mark - Events Table View

- (void)setEventsTableView:(UITableView *)eventsTableView
{
	if (_eventsTableView != eventsTableView)
	{
		_eventsTableView.dataSource = nil;
		_eventsTableView.delegate = nil;
		_eventsTableView = eventsTableView;
		_eventsTableView.dataSource = self;
		_eventsTableView.delegate = self;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.resultsController.events count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	KATGScheduleItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kKATGScheduleItemTableViewCellIdentifier forIndexPath:indexPath];
	KATGScheduledEvent *event = [self.resultsController.events objectAtIndex:indexPath.row];
	[cell configureWithScheduledEvent:event];
	cell.longPressDelegate = self.mainViewController;
	cell.index = indexPath.row;
	return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 75;
}

#pragma mark - Scroll View

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	TDCollectionView *collectionView = self.mainCollectionView;
	if (scrollView == collectionView)
	{
		if (self.collectionViewScrollingAnimationInProgress)
		{
			return;
		}
		
//		KATGSection targetSection = [collectionView closestSectionForContentOffset:scrollView.contentOffset];
		NSParameterAssert(self.mainViewController);
//		[self.mainViewController.tabBar selectTabItemAtIndex:targetSection animated:YES];
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	TDCollectionView *collectionView = self.mainCollectionView;
	if (scrollView == collectionView)
	{
		self.collectionViewScrollingAnimationInProgress = false;
	}
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
	TDCollectionView *collectionView = self.mainCollectionView;
	if (scrollView == collectionView)
	{
		NSIndexPath *nearestIndexPath = [collectionView nearestIndexPathForContentOffset:*targetContentOffset];
		UICollectionViewLayoutAttributes *attributes = [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:nearestIndexPath];
		targetContentOffset->x = attributes.center.x - floorf(collectionView.frame.size.width / 2.0f);
		self.collectionViewScrollingAnimationInProgress = false;
	}
}

- (void)snapToNearestArchiveColumn
{
	TDCollectionView *collectionView = self.mainCollectionView;
	NSIndexPath *nearestIndexPath = [collectionView nearestIndexPathForContentOffset:collectionView.contentOffset];
	if (nearestIndexPath.section == KATGSectionArchive)
	{
		[collectionView scrollToItemAtIndexPath:nearestIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
		self.collectionViewScrollingAnimationInProgress = true;
	}
}

- (NSString *)accessibilityScrollStatusForScrollView:(UIScrollView *)scrollView
{
	TDCollectionView *collectionView = self.mainCollectionView;
	if (scrollView == collectionView)
	{
		//TODO: announce range of shows visisble when in the archive section
		KATGSection targetSection = [collectionView closestSectionForContentOffset:scrollView.contentOffset];
		switch (targetSection) {
			case KATGSectionSchedule:
				return NSLocalizedString(@"scrolled to schedule", nil);
			case KATGSectionLive:
				return NSLocalizedString(@"scrolled to live show", nil);
			case KATGSectionArchive:
				return NSLocalizedString(@"scrolled to episodes", nil);
			default:
				break;
		}
	}
	return nil;
}

@end
