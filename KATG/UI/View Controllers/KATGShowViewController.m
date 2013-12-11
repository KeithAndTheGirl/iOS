//
//  KATGEpisodeViewController_iPhone.m
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

#import "KATGShowViewController.h"
#import "KATGShow.h"
#import "KATGGuest.h"
#import "KATGImage.h"
#import "KATGShowView.h"
#import "TDRoundedShadowView.h"
#import "KATGControlButton.h"
#import "KATGButton.h"
#import "KATGShowGuestCell.h"
#import "KATGShowDescriptionCell.h"
#import "KATGShowImagesTableViewCell.h"
#import "KATGShowSectionTitleCell.h"
#import "KATGDownloadEpisodeCell.h"
#import "KATGPlaybackManager.h"
#import "KATGDataStore.h"
#import "KATGImagesViewController.h"
#import "KATGReachabilityOperation.h"
#import "KATGImageCache.h"

static void * KATGReachabilityObserverContext = @"KATGReachabilityObserverContext";

#define kKATGShowDetailsSectionCellIdentifierImages @"kKATGShowDetailsSectionCellIdentifierImages"
#define kKATGShowDetailsSectionCellIdentifierGuests @"kKATGShowDetailsSectionCellIdentifierGuests"
#define kKATGShowDetailsSectionCellIdentifierDescription @"kKATGShowDetailsSectionCellIdentifierDescription"
#define kKATGShowDetailsSectionTitleCellIdentifier @"kKATGShowDetailsSectionTitleCellIdentifier"
#define kKATGShowDetailsSectionDownloadCellIdentifier @"kKATGShowDetailsSectionDownloadCellIdentifier"

typedef enum {
	KATGShowDetailsSectionGuests,
	KATGShowDetailsSectionDescription,
	KATGShowDetailsSectionImages,
	KATGShowDetailsSectionDownload,
} KATGShowDetailsSection;

#define KATGShowDetailsSectionMaxCount KATGShowDetailsSectionDownload+1

@interface KATGShowViewController () <UITableViewDelegate, UITableViewDataSource, KATGShowImagesCellDelegate, KATGImagesViewControllerDelegate, KATGDownloadEpisodeCellDelegate, UIActionSheetDelegate>
{
	BOOL positionSliderIsDragging;
}

@property (nonatomic) KATGShow *show;
@property (nonatomic) bool shouldReloadDescription;
@property (nonatomic) bool shouldReloadImages;
@property (nonatomic) bool shouldReloadGuests;
@property (nonatomic) bool shouldReloadDownload;

@property (nonatomic) id<KATGDownloadToken> downloadToken;

@property (nonatomic) bool imagesRequested;

// Handy things to check sometimes
- (BOOL)isCurrentShow;

// KATGPlaybackManager setup
- (void)addPlaybackManagerKVO;
- (void)removePlaybackManagerKVO;

// UI Actions
- (void)playButtonPressed:(id)sender;
- (void)backButtonPressed:(id)sender;
- (void)forwardButtonPressed:(id)sender;
- (void)sliderChanged:(id)sender;
- (void)sliderDidBeginDragging:(id)sender;
- (void)sliderDidEndDragging:(id)sender;
- (void)updateControlStates;

@end

@implementation KATGShowViewController

- (id)init
{
	self = [super init];
	if (self)
	{
		[self addPlaybackManagerKVO];
		[self addReachabilityKVO];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readerContextChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:[[KATGDataStore sharedStore] readerContext]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityReturned:) name:kKATGReachabilityIsReachableNotification object:nil];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:[[KATGDataStore sharedStore] readerContext]];
//	[self removePlaybackManagerKVO];
//	[self removeReachabilityKVO];
}

#pragma mark -

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self.tableView registerClass:[KATGShowGuestCell class] forCellReuseIdentifier:kKATGShowDetailsSectionCellIdentifierGuests];
	[self.tableView registerClass:[KATGShowImagesTableViewCell class] forCellReuseIdentifier:kKATGShowDetailsSectionCellIdentifierImages];
	[self.tableView registerClass:[KATGShowDescriptionCell class] forCellReuseIdentifier:kKATGShowDetailsSectionCellIdentifierDescription];
	[self.tableView registerClass:[KATGShowSectionTitleCell class] forCellReuseIdentifier:kKATGShowDetailsSectionTitleCellIdentifier];
	[self.tableView registerClass:[KATGDownloadEpisodeCell class] forCellReuseIdentifier:kKATGShowDetailsSectionDownloadCellIdentifier];
	

	[self.controlsView.skipBackButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlsView.playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlsView.skipForwardButton addTarget:self action:@selector(forwardButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlsView.positionSlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
	[self.controlsView.positionSlider addTarget:self action:@selector(sliderDidBeginDragging:) forControlEvents:UIControlEventTouchDown];
	[self.controlsView.positionSlider addTarget:self action:@selector(sliderDidEndDragging:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchUpInside];
	
	[[KATGDataStore sharedStore] downloadEpisodeDetails:self.show.episode_id];
	
	self.downloadToken = [[KATGDataStore sharedStore] activeEpisodeAudioDownload:self.show];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

    self.showTitleLabel.text = self.show.title;
	self.showNumberLabel.text = [NSString stringWithFormat:@"EPISODE %@", self.show.number];
    self.showTimeLabel.text = [self.show formattedTimestamp];
    
	NSMutableString *guestNames = [[NSMutableString alloc] init];
	if ([self.show.sortedGuests count])
	{
		for (KATGGuest *guest in self.show.sortedGuests)
		{
			if (guestNames.length > 0)
			{
				[guestNames appendString:@"\n"];
			}
			[guestNames appendFormat:@"%@", guest.name];
		}
	}
	else
	{
		[guestNames appendString:@"(no guests)"];
	}

	[self updateControlStates];
}

#pragma mark - Actions

- (IBAction)close:(id)sender
{
	if (self.presentingViewController)
	{
		[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
	}
	else
	{
		[self.delegate closeShowViewController:self];
	}
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *guests = [[self.show valueForKeyPath:@"Guests.name"] allObjects];
    
	switch ((KATGShowDetailsSection)section) {
		case KATGShowDetailsSectionGuests:
            return [guests count]?2:0;
		case KATGShowDetailsSectionDescription:
		case KATGShowDetailsSectionImages:
			return 2;
		case KATGShowDetailsSectionDownload:
			return 1;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// The first row in each section is a header
	if (indexPath.row == 0 && indexPath.section != KATGShowDetailsSectionDownload)
	{
		KATGShowSectionTitleCell *titleCell = [tableView dequeueReusableCellWithIdentifier:kKATGShowDetailsSectionTitleCellIdentifier forIndexPath:indexPath];
        
        NSArray *guests = [[self.show valueForKeyPath:@"Guests.name"] allObjects];
		switch ((KATGShowDetailsSection)indexPath.section)
		{
			case KATGShowDetailsSectionGuests:
				titleCell.showTopRule = YES;
				titleCell.sectionTitleLabel.text = [NSString stringWithFormat:@"%@: %@",
                                                    NSLocalizedString(@"Guests", nil),
                                                    [guests componentsJoinedByString:@", "]];
				break;
			case KATGShowDetailsSectionDescription:
				titleCell.showTopRule = NO;
				titleCell.sectionTitleLabel.text = NSLocalizedString(@"Description", nil);
				break;
			case KATGShowDetailsSectionImages:
				titleCell.showTopRule = YES;
				titleCell.sectionTitleLabel.text = NSLocalizedString(@"Images", nil);
				break;
			case KATGShowDetailsSectionDownload:
				titleCell.showTopRule = YES;
				titleCell.sectionTitleLabel.text = NSLocalizedString(@"", nil);
				break;
		}
		return titleCell;
	}

	UITableViewCell *cell;
	switch ((KATGShowDetailsSection)indexPath.section) 
	{
		case KATGShowDetailsSectionGuests:
		{
            NSArray *guests = self.show.sortedGuests;
            NSMutableArray *images = [NSMutableArray array];
            for (KATGGuest *g in guests) {
                KATGImage *img = g.image;
                [images addObject:img];
            }
            
            KATGShowImagesTableViewCell *imagesCell = [tableView dequeueReusableCellWithIdentifier:kKATGShowDetailsSectionCellIdentifierImages forIndexPath:indexPath];
            imagesCell.images = images;
            imagesCell.delegate = self;
            cell = imagesCell;
			break;
		}

		case KATGShowDetailsSectionDescription:
		{
			KATGShowDescriptionCell *descCell = [tableView dequeueReusableCellWithIdentifier:kKATGShowDetailsSectionCellIdentifierDescription forIndexPath:indexPath];
			if ([self.show.desc length])
			{
				descCell.descriptionLabel.text = self.show.desc;
			}
			else
			{
				descCell.descriptionLabel.text = NSLocalizedString(@"(no description)", @"");
			}
			//descCell.descriptionLabel.text = kKATGDescriptionDummyText;
			cell = descCell;
			break;
		}
		case KATGShowDetailsSectionImages:
			if ([self.show.images count])
			{
				KATGShowImagesTableViewCell *imagesCell = [tableView dequeueReusableCellWithIdentifier:kKATGShowDetailsSectionCellIdentifierImages forIndexPath:indexPath];
				imagesCell.images = [self.show.images sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
				imagesCell.delegate = self;
				cell = imagesCell;
			}
			else
			{
				KATGShowSectionTitleCell *titleCell = [tableView dequeueReusableCellWithIdentifier:kKATGShowDetailsSectionTitleCellIdentifier forIndexPath:indexPath];
				titleCell.showTopRule = NO;
				titleCell.sectionTitleLabel.text = NSLocalizedString(@"(no images)", nil);
				cell = titleCell;
			}
			break;
		case KATGShowDetailsSectionDownload:
		{
			KATGDownloadEpisodeCell *downloadCell = [tableView dequeueReusableCellWithIdentifier:kKATGShowDetailsSectionDownloadCellIdentifier forIndexPath:indexPath];
			downloadCell.delegate = self;
			if ([[self.show downloaded] boolValue])
			{
				downloadCell.state = KATGDownloadEpisodeCellStateDownloaded;
			}
			else if (self.downloadToken)
			{
				[self downloadButtonPressed:downloadCell];
			}
			else if (![[KATGDataStore sharedStore] isReachableViaWifi])
			{
				downloadCell.state = KATGDownloadEpisodeCellStateDisabled;
			}
			cell = downloadCell;
			break;
		}
	}
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch ((KATGShowDetailsSection)indexPath.section) {
		case KATGShowDetailsSectionGuests:
			if (indexPath.row == 0)
			{
				return 44.0f;
			}
			return 110.0f;
		case KATGShowDetailsSectionDescription:
			if (indexPath.row == 0)
			{
				return 44.0f;
			}
			return [KATGShowDescriptionCell cellHeightWithString:self.show.desc ?: NSLocalizedString(@"(no description)", @"") width:tableView.frame.size.width];
		case KATGShowDetailsSectionImages:
			if (indexPath.row == 0)
			{
				return 44.0f;
			}
			else if ([self.show.images count])
			{
				return 92.0f;
			}
			return 24.0f;
		case KATGShowDetailsSectionDownload:
			return 64.0f;
		default:
			return 44.0f;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section != KATGShowDetailsSectionGuests || indexPath.row == 0)
	{
		return;
	}
	UIViewController *guestViewController = [[UIViewController alloc] init];
	[self.navigationController pushViewController:guestViewController animated:YES];
}

#pragma mark - playback

- (BOOL)isCurrentShow
{
	NSNumber *currentShowEpisodeID = [KATGPlaybackManager sharedManager].currentShow.episode_id;
	if (currentShowEpisodeID == nil)
	{
		return NO;
	}
	BOOL isCurrentShow = [self.show.episode_id isEqualToNumber:currentShowEpisodeID];
	return isCurrentShow;
}

#pragma mark - KATGPlaybackManager

- (void)addPlaybackManagerKVO
{
	[[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:KATGCurrentTimeObserverKey options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
	[[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:KATGStateObserverKey options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
}

- (void)removePlaybackManagerKVO
{
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:KATGCurrentTimeObserverKey];
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:KATGStateObserverKey];
}

#pragma mark - Reachability

- (void)addReachabilityKVO
{
	[[KATGDataStore sharedStore] addObserver:self forKeyPath:kKATGDataStoreIsReachableViaWifiKey options:0 context:KATGReachabilityObserverContext];
}

- (void)removeReachabilityKVO
{
	[[KATGDataStore sharedStore] removeObserver:self forKeyPath:kKATGDataStoreIsReachableViaWifiKey context:KATGReachabilityObserverContext];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == KATGReachabilityObserverContext)
	{
		self.shouldReloadDownload = true;
		[self queueReload];
		return;
	}
	if (![self isCurrentShow])
	{
		return;
	}
	if ([keyPath isEqualToString:KATGCurrentTimeObserverKey])
	{
		if (!positionSliderIsDragging)
		{
			Float64 currentTime = CMTimeGetSeconds([[KATGPlaybackManager sharedManager] currentTime]);
			if (isnan(currentTime))
			{
				currentTime = 0.0;
			}
			Float64 duration = CMTimeGetSeconds([[KATGPlaybackManager sharedManager] duration]);
			if (isnan(duration))
			{
				duration = 1.0;
			}
			self.controlsView.positionSlider.value = currentTime;
			self.controlsView.positionSlider.maximumValue = duration;
		}
	}
	else if ([keyPath isEqualToString:KATGStateObserverKey])
	{
		[self updateControlStates];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - UI Actions

- (void)playButtonPressed:(id)sender
{
	if (![[KATGDataStore sharedStore] isReachableViaWifi] && ![self.show.downloaded boolValue])
	{
		[[[UIAlertView alloc] initWithTitle:@"Streaming Unavailable" message:@"Streaming is not available over a cellular connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
		return;
	}
	if (![self isCurrentShow])
	{
		[[KATGPlaybackManager sharedManager] configureWithShow:self.show];
		[[KATGPlaybackManager sharedManager] play];
		return;
	}
	if ([[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying)
	{
		[[KATGPlaybackManager sharedManager] pause];
	}
	else
	{
		[[KATGPlaybackManager sharedManager] play];
	}
}

- (void)backButtonPressed:(id)sender
{
	[[KATGPlaybackManager sharedManager] jumpBackward];
}

- (void)forwardButtonPressed:(id)sender
{
	[[KATGPlaybackManager sharedManager] jumpForward];
}

- (void)sliderChanged:(id)sender
{
	[self seekToTimeBasedOnSlider];
}

- (void)sliderDidBeginDragging:(id)sender
{
	positionSliderIsDragging = YES;
}

- (void)sliderDidEndDragging:(id)sender
{
	positionSliderIsDragging = NO;
	[self seekToTimeBasedOnSlider];
}

- (void)seekToTimeBasedOnSlider
{
	CMTime currentTime = CMTimeMakeWithSeconds(self.controlsView.positionSlider.value, 1);
	[[KATGPlaybackManager sharedManager] seekToTime:currentTime];
}

- (void)updateControlStates
{
	if ([self isCurrentShow])
	{
		self.controlsView.currentState = [[KATGPlaybackManager sharedManager] state];
	}
	else
	{
		self.controlsView.currentState = KATGAudioPlayerStateDone;
	}
    [self.controlsView setNeedsLayout];
}

#pragma mark - Data updates

NS_INLINE bool statusHasFlag(KATGShowObjectStatus status, KATGShowObjectStatus flag)
{
	return ((status & flag) == flag);
}

- (void)readerContextChanged:(NSNotification *)note
{
	NSParameterAssert([NSThread isMainThread]);
	KATGShowObjectStatus status = [self.show showStatusBasedOnNotification:note checkRelationships:true];
	if (status == KATGShowObjectStatusAllInvalidated)
	{
		self.show = nil;
		[self clearReloadFlags];
		[self.tableView reloadData];
		return;
	}
	bool showDeleted = statusHasFlag(status, KATGShowObjectStatusShowDeleted);
	if (showDeleted)
	{
		[self clearReloadFlags];
		[self showDeleted];
		return;
	}
	if (!self.shouldReloadDescription)
	{
		self.shouldReloadDescription = statusHasFlag(status, KATGShowObjectStatusShowReload);
	}
	bool imagesDeleted = statusHasFlag(status, KATGShowObjectStatusImagesDeleted);
	if (!self.shouldReloadImages)
	{
		self.shouldReloadImages = imagesDeleted || statusHasFlag(status, KATGShowObjectStatusImagesReload) || statusHasFlag(status, KATGShowObjectStatusImagesInserted);
		if (self.shouldReloadImages && !self.imagesRequested && [self.show.images count])
		{
			[[KATGImageCache imageCache] requestImages:[self.show.images valueForKey:KATGImageMediaURLAttributeName] size:CGSizeZero];
			self.imagesRequested = true;
		}
	}
	bool guestsDeleted = statusHasFlag(status, KATGShowObjectStatusGuestsDeleted);
	if (!self.shouldReloadGuests)
	{
		self.shouldReloadGuests = guestsDeleted || statusHasFlag(status, KATGShowObjectStatusGuestsReload) || statusHasFlag(status, KATGShowObjectStatusGuestsInserted);
	}
	if (self.shouldReloadDescription || self.shouldReloadImages || self.shouldReloadGuests)
	{
		// Handle deletes right away, otherwise, defer
		if (imagesDeleted || guestsDeleted)
		{
			[self doReload];
		}
		else
		{
			[self queueReload];
		}
	}
}

- (void)showDeleted
{
	NSParameterAssert([NSThread isMainThread]);
	self.showObjectID = nil;
	[self.tableView reloadData];
	NSLog(@"Show deleted");
}

- (void)queueReload
{
	NSParameterAssert([NSThread isMainThread]);
	CFTypeRef cfSelf = CFBridgingRetain(self);
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doReload) object:nil];
	[self performSelector:@selector(doReload) withObject:nil afterDelay:0.1];
	CFRelease(cfSelf);
}

- (void)doReload
{
	NSParameterAssert([NSThread isMainThread]);
	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	if (self.shouldReloadDescription)
	{
		[indexSet addIndex:KATGShowDetailsSectionDescription];
	}
	if (self.shouldReloadImages)
	{
		[indexSet addIndex:KATGShowDetailsSectionImages];
	}
	if (self.shouldReloadGuests)
	{
		[indexSet addIndex:KATGShowDetailsSectionGuests];
	}
	if (self.shouldReloadDownload)
	{
		[indexSet addIndex:KATGShowDetailsSectionDownload];
	}
	if ([indexSet count] == KATGShowDetailsSectionMaxCount)
	{
		[self.tableView reloadData];
	}
	else
	{
		[self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	[self clearReloadFlags];
}

- (void)clearReloadFlags
{
	self.shouldReloadDescription = false;
	self.shouldReloadImages = false;
	self.shouldReloadGuests = false;
	self.shouldReloadDownload = false;
}

- (KATGShow *)show
{
	if (_show)
	{
		return _show;
	}
	NSManagedObjectID *showObjectID = self.showObjectID;
	if (showObjectID)
	{
		_show = (KATGShow *)[[[KATGDataStore sharedStore] readerContext] existingObjectWithID:self.showObjectID error:nil];
	}
	return _show;
}

- (void)setShowObjectID:(NSManagedObjectID *)showObjectID
{
	if (![_showObjectID isEqual:showObjectID])
	{
		_showObjectID = showObjectID;
		self.show = nil;
	}
}

#pragma mark - Images Cell Delegate

- (void)showImagesCell:(KATGShowImagesTableViewCell *)imagesCell thumbnailWasTappedForImage:(KATGImage *)image inImageView:(UIImageView *)imageView
{
	KATGImagesViewController *imagesViewController = [[KATGImagesViewController alloc] initWithNibName:nil bundle:nil];
	imagesViewController.delegate = self;
	imagesViewController.images = [self.show.images sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
    
    //imagesCell.images;
	
    [imagesViewController willMoveToParentViewController:self];
	[self addChildViewController:imagesViewController];
	[self.view addSubview:imagesViewController.view];
	imagesViewController.view.frame = self.view.bounds;

//	__weak KATGShowViewController *weakSelf = self;
	[imagesViewController transitionFromImage:image
								  inImageView:imageView
								   animations:^{
//									   weakSelf.showView.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
								   } completion:^{

								   }];
}

#pragma mark - Images View Controller Delegate

- (void)closeImagesViewController:(KATGImagesViewController *)viewController
{
	[viewController willMoveToParentViewController:nil];
	[viewController removeFromParentViewController];
	[viewController.view removeFromSuperview];
}

- (UIView *)imagesViewController:(KATGImagesViewController *)viewController viewToCollapseIntoForImage:(KATGImage *)image
{
	KATGShowImagesTableViewCell *imagesCell = (KATGShowImagesTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:KATGShowDetailsSectionImages]];
	NSInteger index = [imagesCell.images indexOfObject:image];
	[imagesCell scrollToImageAtIndex:index animated:NO];
	[imagesCell layoutIfNeeded];
	return [imagesCell viewForImageAtIndex:index];
}

- (void)performAnimationsWhileImagesViewControllerIsClosing:(KATGImagesViewController *)viewController
{
	
}

#pragma mark - 

- (void)downloadButtonPressed:(KATGDownloadEpisodeCell *)cell
{
	if (cell.state == KATGDownloadEpisodeCellStateActive)
	{
		cell.state = KATGDownloadEpisodeCellStateDownloading;
		cell.progress = 0.0f;
		typeof(*self) *weakSelf = self;
		void (^progress)(CGFloat progress) = ^(CGFloat progress) {
			NSParameterAssert([NSThread isMainThread]);
			typeof(*self) *strongSelf = weakSelf;
			if (strongSelf)
			{
				KATGDownloadEpisodeCell *downloadCell = (KATGDownloadEpisodeCell *)[strongSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:KATGShowDetailsSectionDownload]];
				if (downloadCell.state == KATGDownloadEpisodeCellStateDownloading)
				{
					downloadCell.progress = progress;
				}
			}
		};
		self.downloadToken = [[KATGDataStore sharedStore] downloadEpisodeAudio:self.show progress:progress completion:^(NSError *error) {
			NSParameterAssert([NSThread isMainThread]);
			typeof(*self) *strongSelf = weakSelf;
			if (strongSelf)
			{
				strongSelf.downloadToken = nil;
				KATGDownloadEpisodeCell *downloadCell = (KATGDownloadEpisodeCell *)[strongSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:KATGShowDetailsSectionDownload]];
				if (downloadCell)
				{
					cell.state = KATGDownloadEpisodeCellStateDownloaded;
					strongSelf.shouldReloadDownload = true;
					[strongSelf queueReload];
				}
			}
		}];
	}
	else if (cell.state == KATGDownloadEpisodeCellStateDownloading)
	{
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Download in progress"
																														 delegate:self
																										cancelButtonTitle:@"Dismiss"
																							 destructiveButtonTitle:@"Cancel download"
																										otherButtonTitles:nil];
		
		[actionSheet showInView:self.view];
		
//		NSParameterAssert(self.downloadToken);
//		[self.downloadToken cancel];
//		self.downloadToken = nil;
//		cell.state = KATGDownloadEpisodeCellStateActive;
//		self.shouldReloadDownload = true;
//		[self queueReload];
	}
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.destructiveButtonIndex)
	{
		if (self.downloadToken)
		{
			KATGDownloadEpisodeCell *cell = (KATGDownloadEpisodeCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:KATGShowDetailsSectionDownload]];
			NSParameterAssert(self.downloadToken);
			[self.downloadToken cancel];
			self.downloadToken = nil;
			cell.state = KATGDownloadEpisodeCellStateActive;
			self.shouldReloadDownload = true;
			[self queueReload];
		}
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
}

#pragma mark - Reachability

- (void)reachabilityReturned:(NSNotification *)note
{
	NSParameterAssert([NSThread isMainThread]);
	[[KATGDataStore sharedStore] downloadEpisodeDetails:self.show.episode_id];
}

@end
