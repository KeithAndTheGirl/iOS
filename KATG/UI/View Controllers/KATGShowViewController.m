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
#import "KATGForumCell.h"
#import "KATGPlaybackManager.h"
#import "KATGDataStore.h"
#import "KATGAudioDownloadManager.h"
#import "KATGImagesViewController.h"
#import "KATGReachabilityOperation.h"
#import "KATGImageCache.h"
#import "KATGVipLoginViewController.h"
#import "KATGURLProtocol.h"
#import "UIKit+AFNetworking.h"
#import "XCDYouTubeKit.h"
#import "KATGDownloadToken.h"
#import "KATGAlert.h"

static void * KATGReachabilityObserverContext = @"KATGReachabilityObserverContext";

#define kKATGShowDetailsSectionCellIdentifierImages @"kKATGShowDetailsSectionCellIdentifierImages"
#define kKATGShowDetailsSectionCellIdentifierGuests @"kKATGShowDetailsSectionCellIdentifierGuests"
#define kKATGShowDetailsSectionCellIdentifierDescription @"kKATGShowDetailsSectionCellIdentifierDescription"
#define kKATGShowDetailsSectionTitleCellIdentifier @"kKATGShowDetailsSectionTitleCellIdentifier"
#define kKATGShowDetailsSectionDownloadCellIdentifier @"kKATGShowDetailsSectionDownloadCellIdentifier"
#define kKATGShowDetailsSectionForumCellIdentifier @"kKATGShowDetailsSectionForumCellIdentifier"

typedef enum {
	KATGShowDetailsSectionPreview,
	KATGShowDetailsSectionVideo,
	KATGShowDetailsSectionGuests,
	KATGShowDetailsSectionDescription,
	KATGShowDetailsSectionImages,
	KATGShowDetailsSectionDownload,
} KATGShowDetailsSection;

#define KATGShowDetailsSectionMaxCount KATGShowDetailsSectionDownload+1

@interface KATGShowViewController () <UITableViewDelegate, UITableViewDataSource, KATGShowImagesCellDelegate, KATGImagesViewControllerDelegate, KATGDownloadEpisodeCellDelegate, UIActionSheetDelegate, KATGForumCellDelegate>
{
	BOOL positionSliderIsDragging;
}

@property (nonatomic) KATGShow *show;
@property (nonatomic) bool shouldReloadDescription;
@property (nonatomic) bool shouldReloadImages;
@property (nonatomic) bool shouldReloadGuests;
@property (nonatomic) bool shouldReloadDownload;

@property (nonatomic) KATGDownloadToken *downloadToken;
@property double downloadProgress;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

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

- (void)dealloc
{
}

#pragma mark -

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    self.tableView.tableHeaderView = self.showHeaderView;
    self.tableView.scrollsToTop = YES;
    self.showTitleLabel.text = @"";
	self.showNumberLabel.text = @"";
    self.showTimeLabel.text = @"";
    
	[self.tableView registerClass:[KATGShowGuestCell class] forCellReuseIdentifier:kKATGShowDetailsSectionCellIdentifierGuests];
	[self.tableView registerClass:[KATGShowImagesTableViewCell class] forCellReuseIdentifier:kKATGShowDetailsSectionCellIdentifierImages];
	[self.tableView registerClass:[KATGShowDescriptionCell class] forCellReuseIdentifier:kKATGShowDetailsSectionCellIdentifierDescription];
	[self.tableView registerClass:[KATGShowSectionTitleCell class] forCellReuseIdentifier:kKATGShowDetailsSectionTitleCellIdentifier];
	[self.tableView registerClass:[KATGDownloadEpisodeCell class] forCellReuseIdentifier:kKATGShowDetailsSectionDownloadCellIdentifier];
	[self.tableView registerClass:[KATGForumCell class] forCellReuseIdentifier:kKATGShowDetailsSectionForumCellIdentifier];

	[self.controlsView.skipBackButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlsView.playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlsView.skipForwardButton addTarget:self action:@selector(forwardButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.controlsView.positionSlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
	[self.controlsView.positionSlider addTarget:self action:@selector(sliderDidBeginDragging:) forControlEvents:UIControlEventTouchDown];
	[self.controlsView.positionSlider addTarget:self action:@selector(sliderDidEndDragging:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchUpInside];
	
	[[KATGDataStore sharedStore] downloadEpisodeDetails:self.show.episode_id];
	
	self.downloadToken = [[KATGAudioDownloadManager sharedManager] activeEpisodeAudioDownload:self.show];
    
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reachabilityReturned:) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    if([self canPerformAction:@selector(setNeedsStatusBarAppearanceUpdate) withSender:self])
        [self setNeedsStatusBarAppearanceUpdate];

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readerContextChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:[[KATGDataStore sharedStore] readerContext]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityReturned:) name:kKATGReachabilityIsReachableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:KATGDataStoreShowDidChangeNotification object:nil];
    
    self.downloadProgress = 0.0;
    if (self.show.downloaded && [[NSURL fileURLWithPath:[self.show getFilePath]] checkResourceIsReachableAndReturnError:nil])
    {
        NSNumber *sizeObject;
        if ([[NSURL fileURLWithPath:[self.show getFilePath]] getResourceValue:&sizeObject forKey:NSURLFileSizeKey error:nil])
        {
            self.downloadProgress = (double)[sizeObject intValue] / [self.show.fileSize intValue];
        }
    }
    
    [self addPlaybackManagerKVO];
    [self addReachabilityKVO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kKATGReachabilityIsReachableNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:[[KATGDataStore sharedStore] readerContext]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KATGDataStoreShowDidChangeNotification object:nil];
    
    	[self removePlaybackManagerKVO];
    	[self removeReachabilityKVO];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate {
    return NO;
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
    [self.refreshControl endRefreshing];
	return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *guests = [[self.show valueForKeyPath:@"Guests.name"] allObjects];
    
	switch ((KATGShowDetailsSection)section) {
        case KATGShowDetailsSectionPreview:
            if([self.show.preview_url length] && ([self.show.preview_url rangeOfString:@"youtube"].location != NSNotFound || [self.show.preview_url rangeOfString:@"mp3"].location != NSNotFound))
                return 2;
            else
                return 0;
        case KATGShowDetailsSectionVideo:
            return [self.show.video_file_url length]?2:0;
		case KATGShowDetailsSectionGuests:
            return [guests count]?2:0;
		case KATGShowDetailsSectionDescription:
            return [self.show.desc length]?2:0;
		case KATGShowDetailsSectionImages:
			return [self.show.images count]?2:0;
		case KATGShowDetailsSectionDownload:
			return 2;
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
			case KATGShowDetailsSectionPreview:
				titleCell.showTopRule = NO;
				titleCell.sectionTitleLabel.text = NSLocalizedString(@"Preview", nil);
                titleCell.contentView.backgroundColor = [UIColor whiteColor];
                break;
            case KATGShowDetailsSectionVideo:
				titleCell.showTopRule = NO;
				titleCell.sectionTitleLabel.text = NSLocalizedString(@"Full episode", nil);
                titleCell.contentView.backgroundColor = [UIColor whiteColor];
                break;
			case KATGShowDetailsSectionGuests:
				titleCell.showTopRule = YES;
				titleCell.sectionTitleLabel.text = [NSString stringWithFormat:@"%@: %@",
                                                    NSLocalizedString(@"Guests", nil),
                                                    [guests componentsJoinedByString:@", "]];
                titleCell.contentView.backgroundColor = [UIColor whiteColor];
                titleCell.sectionTitleLabel.numberOfLines = 10;
				break;
			case KATGShowDetailsSectionDescription:
				titleCell.showTopRule = NO;
				titleCell.sectionTitleLabel.text = NSLocalizedString(@"Description", nil);
                titleCell.contentView.backgroundColor = [UIColor colorWithRed:243./255 green:244./255 blue:246./255 alpha:1];
				break;
			case KATGShowDetailsSectionImages:
				titleCell.showTopRule = YES;
				titleCell.sectionTitleLabel.text = NSLocalizedString(@"Images", nil);
                titleCell.contentView.backgroundColor = [UIColor whiteColor];
				break;
			case KATGShowDetailsSectionDownload:
				titleCell.showTopRule = YES;
				titleCell.sectionTitleLabel.text = NSLocalizedString(@"", nil);
                titleCell.contentView.backgroundColor = [UIColor whiteColor];
				break;
		}
		return titleCell;
	}

	UITableViewCell *cell;
	switch ((KATGShowDetailsSection)indexPath.section) 
	{
		case KATGShowDetailsSectionPreview:
        {
            if(!self.previewCell) {
                self.previewCell = [[KATGShowPreviewCell alloc] init];
                self.previewCell.previewURL = self.show.preview_url;
                self.previewCell.delegate = self;
            }
            cell = self.previewCell;
            break;
        }
        case KATGShowDetailsSectionVideo:
        {
            cell = [[UITableViewCell alloc] init];
            if(!self.videoButton) {
                self.videoButton = [[UIButton alloc] init];
                self.videoButton.adjustsImageWhenHighlighted = NO;
                self.videoButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
                self.videoButton.autoresizingMask = 63;
                self.videoButton.backgroundColor = [UIColor blackColor];
                [self.videoButton setBackgroundImageForState:UIControlStateNormal withURL:[NSURL URLWithString:self.show.video_thumbnail_url]];
                [self.videoButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
                [self.videoButton addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
            }
            self.videoButton.frame = CGRectInset(cell.bounds, 0, 4);
            cell.backgroundColor = [UIColor blackColor];
            [cell addSubview:self.videoButton];
            break;
        }
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
            cell.contentView.backgroundColor = [UIColor whiteColor];
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
            cell.contentView.backgroundColor = [UIColor colorWithRed:243./255 green:244./255 blue:246./255 alpha:1];
			break;
		}
		case KATGShowDetailsSectionImages:
			if ([self.show.images count])
			{
				KATGShowImagesTableViewCell *imagesCell = [tableView dequeueReusableCellWithIdentifier:kKATGShowDetailsSectionCellIdentifierImages forIndexPath:indexPath];
				imagesCell.images = [self.show.images sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
				imagesCell.delegate = self;
				cell = imagesCell;
                cell.contentView.backgroundColor = [UIColor whiteColor];
			}
			else
			{
				KATGShowSectionTitleCell *titleCell = [tableView dequeueReusableCellWithIdentifier:kKATGShowDetailsSectionTitleCellIdentifier forIndexPath:indexPath];
				titleCell.showTopRule = NO;
				titleCell.sectionTitleLabel.text = NSLocalizedString(@"(no images)", nil);
				cell = titleCell;
                cell.contentView.backgroundColor = [UIColor whiteColor];
			}
			break;
		case KATGShowDetailsSectionDownload:
		{
            if(indexPath.row == 0) {
                KATGForumCell *forumCell = [tableView dequeueReusableCellWithIdentifier:kKATGShowDetailsSectionForumCellIdentifier forIndexPath:indexPath];
                forumCell.delegate = self;
                cell = forumCell;
                cell.contentView.backgroundColor = [UIColor whiteColor];
				if([self.show.forum_url length] == 0)
                    cell.hidden = YES;
            }
            else if(indexPath.row == 1) {
                KATGDownloadEpisodeCell *downloadCell = [tableView dequeueReusableCellWithIdentifier:kKATGShowDetailsSectionDownloadCellIdentifier forIndexPath:indexPath];
                downloadCell.delegate = self;
                if ([[self.show downloaded] boolValue])
                {
                    downloadCell.state = KATGDownloadEpisodeCellStateDownloaded;
                }
                else if (self.downloadToken)
                {
                    downloadCell.state = KATGDownloadEpisodeCellStateDownloading;
                    downloadCell.progress = self.downloadProgress;
                }
                else if (![[KATGDataStore sharedStore] isReachable] || [[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStateLoading || [[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying)
                {
                    downloadCell.state = KATGDownloadEpisodeCellStateDisabled;
                }
                else
                {
                    downloadCell.state = KATGDownloadEpisodeCellStateActive;
                    downloadCell.progress = self.downloadProgress;
                }
                downloadCell.showTopRule = [self.show.forum_url length] == 0;
                cell = downloadCell;
                cell.contentView.backgroundColor = [UIColor whiteColor];
            }
			break;
		}
	}
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch ((KATGShowDetailsSection)indexPath.section) {
		case KATGShowDetailsSectionPreview:
            if (indexPath.row == 0)
			{
				return 44.0f;
			}
            if([self.show.preview_url rangeOfString:@"mp3"].location != NSNotFound)
                return 44;
			return 220.0f;
        case KATGShowDetailsSectionVideo:
            if (indexPath.row == 0)
			{
				return 44.0f;
			}
			return 220.0f;
		case KATGShowDetailsSectionGuests:
			if (indexPath.row == 0)
			{
                NSArray *guests = [[self.show valueForKeyPath:@"Guests.name"] allObjects];
                NSString *text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Guests", nil), [guests componentsJoinedByString:@", "]];
                CGFloat cellHeight = [text sizeWithFont:[UIFont boldSystemFontOfSize:12]
                                               constrainedToSize:CGSizeMake(320, 440)].height * 1.1;
				return cellHeight + 30;
			}
            int rows = ceil([self.show.guests count]/3.);
            return 104*rows;
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
                int rows = ceil([self.show.images count]/3.);
				return 104*rows;
			}
			return 24.0f;
		case KATGShowDetailsSectionDownload:
            if (indexPath.row == 0)
			{
				if([self.show.forum_url length] > 0) {
                    return 64;
                }
                else {
                    return 0;
                }
			}
			else if (indexPath.row == 1)
			{
                return 64.0f;
			}
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
    [self configureTopBar];
}

- (void)removePlaybackManagerKVO
{
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:KATGCurrentTimeObserverKey];
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:KATGStateObserverKey];
}

#pragma mark - Reachability

- (void)addReachabilityKVO
{
	[[KATGDataStore sharedStore] addObserver:self forKeyPath:kKATGDataStoreIsReachableKey options:0 context:KATGReachabilityObserverContext];
}

- (void)removeReachabilityKVO
{
	[[KATGDataStore sharedStore] removeObserver:self forKeyPath:kKATGDataStoreIsReachableKey context:KATGReachabilityObserverContext];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:KATGStateObserverKey])
	{
        [self configureTopBar];
    }
	if (context == KATGReachabilityObserverContext)
	{
		self.shouldReloadDownload = true;
		[self queueReload];
		return;
	}
	if (![self isCurrentShow])
	{
        Float64 currentTime = [self.show.lastPlaybackTime floatValue];
        if (isnan(currentTime))
        {
            currentTime = 0.0;
        }
        Float64 duration = [[self.show duration] floatValue];
        if (isnan(duration))
        {
            duration = 1.0;
        }
        // this works while no playing
        self.controlsView.positionSlider.maximumValue = duration;
        self.controlsView.positionSlider.loadedValue = duration*self.downloadProgress;
        self.controlsView.positionSlider.value = currentTime;
        [self.controlsView setNeedsLayout];
		return;
	}
	if ([keyPath isEqualToString:KATGCurrentTimeObserverKey])
	{
		if (!positionSliderIsDragging)
		{
			Float64 currentTime = CMTimeGetSeconds([[KATGPlaybackManager sharedManager] currentTime]);
            if (isnan(currentTime))
            {
                currentTime = [self.show.lastPlaybackTime floatValue];
            }
            if (isnan(currentTime))
            {
                currentTime = 0.0;
            }
            Float64 wholeDuration = [[self.show duration] floatValue];
            Float64 availabelDuration = CMTimeGetSeconds([[KATGPlaybackManager sharedManager] availabelDuration]);
			
			self.controlsView.positionSlider.maximumValue = wholeDuration;
            self.controlsView.positionSlider.loadedValue = availabelDuration;
			self.controlsView.positionSlider.value = currentTime;
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

#pragma markKATGShowPreviewCellDelegate
-(void)audioPreviewAction {
    [[KATGPlaybackManager sharedManager] stop];
    MPMoviePlayerViewController *mpvc = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:self.show.preview_url]];
    mpvc.moviePlayer.shouldAutoplay = YES;
    [self presentMoviePlayerViewControllerAnimated:mpvc];
}

-(void)videoPreviewAction:(NSString*)videoID {
    [[KATGPlaybackManager sharedManager] stop];
    XCDYouTubeVideoPlayerViewController *videoController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:videoID];
    [self presentMoviePlayerViewControllerAnimated:videoController];
}

#pragma mark - UI Actions
-(void)playVideo {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString *key = [def valueForKey:KATG_PLAYBACK_KEY];
    NSString *uid = [def valueForKey:KATG_PLAYBACK_UID];
    if(self.needAuth) {
        if(!key || !uid) {
            KATGVipLoginViewController *loginController = [[KATGVipLoginViewController alloc] init];
            loginController.completion = (^() {
                [self dismissViewControllerAnimated:YES completion:nil];
                [self playVideo];
            });
            [self presentViewController:loginController animated:YES completion:nil];
            return;
        }
    }
    [[KATGPlaybackManager sharedManager] stop];
    
    NSURL *videoUrl = [NSURL URLWithString:self.show.video_file_url];
    [KATGUtil setCookieWithName:KATG_PLAYBACK_UID value:[[def valueForKey:KATG_PLAYBACK_UID] stringValue]  forURL:videoUrl];
    [KATGUtil setCookieWithName:KATG_PLAYBACK_KEY value:[def valueForKey:KATG_PLAYBACK_KEY]  forURL:videoUrl];
    XCDYouTubeVideoPlayerViewController *mpvc = [[XCDYouTubeVideoPlayerViewController alloc] initWithContentURL:videoUrl];
    mpvc.moviePlayer.initialPlaybackTime = [[[NSUserDefaults standardUserDefaults] objectForKey:self.show.video_file_url] doubleValue];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    
    [self presentMoviePlayerViewControllerAnimated:mpvc];
}

- (void) moviePlayBackDidFinish:(NSNotification*)notification {
    NSError *error = [[notification userInfo] objectForKey:@"error"];
    if (error) {
        NSString *authError = [KATGURLProtocol errorForUrlString:self.show.video_file_url];
        if(authError)
            error = [NSError errorWithDomain:@"KATG moviePlayBackDidFinish error"
                                        code:0
                                    userInfo:@{NSLocalizedDescriptionKey: authError}];
        [UIAlertView errorWithTitle:@"Error" error:error];
    }
    else {
        MPMoviePlayerController *mpc = notification.object;
        NSTimeInterval currentTime = mpc.currentPlaybackTime;
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:currentTime] forKey:[mpc.contentURL absoluteString]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void)playButtonPressed:(id)sender
{
    if ([self isCurrentShow] && [[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying)
	{
		[[KATGPlaybackManager sharedManager] pause];
	}
	else
	{
        if (![self isCurrentShow]) {
            if([[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying) {
                [[KATGPlaybackManager sharedManager] stop];
            }
            [[KATGPlaybackManager sharedManager] configureWithShow:self.show];
        }
        [[KATGPlaybackManager sharedManager] play];
	}
    [self updateControlStates];
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
    if([[KATGPlaybackManager sharedManager] state] != KATGAudioPlayerStatePlaying || [self isCurrentShow])
        [[KATGPlaybackManager sharedManager] seekToTime:currentTime];
    if(![self isCurrentShow]) {
        self.show.lastPlaybackTime = @(self.controlsView.positionSlider.value);
    }
}

- (void)updateControlStates
{
    if (self.downloadToken) {
        self.controlsView.currentState = KATGAudioPlayerStateLoading;
    }
	else if ([self isCurrentShow])
	{
		self.controlsView.currentState = [[KATGPlaybackManager sharedManager] state];
	}
	else
	{
		self.controlsView.currentState = KATGAudioPlayerStateDone;
	}
    
    Float64 currentTime = [self.show.lastPlaybackTime floatValue];
    Float64 wholeDuration = [[self.show duration] floatValue];
    Float64 availabelDuration = CMTimeGetSeconds([[KATGPlaybackManager sharedManager] availabelDuration]);
    
    self.controlsView.positionSlider.maximumValue = wholeDuration;
    self.controlsView.positionSlider.loadedValue = availabelDuration;
    self.controlsView.positionSlider.value = currentTime;
    [self.controlsView setNeedsLayout];
    
    if([[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStateFailed) {
        NSError *error = [[KATGPlaybackManager sharedManager] getCurrentError];
        NSString *urlString = [[error.userInfo valueForKey:NSURLErrorKey] absoluteString];
        NSString *authError = [KATGURLProtocol errorForUrlString:urlString];
        if(authError) {
            [[[UIAlertView alloc] initWithTitle:@"Playback failed"
                                        message:@"Please enter your VIP account email and password to access this feed."
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
        else {
            [UIAlertView errorWithTitle:@"Playback failed" error:[[KATGPlaybackManager sharedManager] getCurrentError]];
        }
        [[KATGPlaybackManager sharedManager] stop];
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:KATGShowDetailsSectionDownload] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [KATGVipLoginViewController logout];
    [self playButtonPressed:nil];
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
    [self.tableView reloadData];
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
	imagesViewController.images = imagesCell.images;
    
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
    if(imagesCell == nil || index == NSNotFound) {
        KATGShowImagesTableViewCell *guestCell = (KATGShowImagesTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:KATGShowDetailsSectionGuests]];
        index = [guestCell.images indexOfObject:image];
        [guestCell scrollToImageAtIndex:index animated:NO];
        [guestCell layoutIfNeeded];
        return [guestCell viewForImageAtIndex:index];
    }
	[imagesCell scrollToImageAtIndex:index animated:NO];
	[imagesCell layoutIfNeeded];
	return [imagesCell viewForImageAtIndex:index];
}

- (void)performAnimationsWhileImagesViewControllerIsClosing:(KATGImagesViewController *)viewController
{
	
}

#pragma mark -
- (void)forumButtonPressed:(KATGForumCell *)cell {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.show.forum_url]];
}

-(void)downloadButtonPressed:(id)sender {
    [self downloadEpisode];
    [self updateControlStates];
}

- (void)downloadEpisode
{
	if (!self.downloadToken && ![self.show.downloaded boolValue])
	{
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        NSString *key = [def valueForKey:KATG_PLAYBACK_KEY];
        NSString *uid = [def valueForKey:KATG_PLAYBACK_UID];
        if(self.needAuth) {
            if(!key || !uid) {
                KATGVipLoginViewController *loginController = [[KATGVipLoginViewController alloc] init];
                loginController.completion = (^() {
                    [self dismissViewControllerAnimated:YES completion:nil];
                    [self downloadEpisode];
                });
                [self presentViewController:loginController animated:YES completion:nil];
                return;
            }
        }
        
        [self.tableView scrollRectToVisible:CGRectMake(0, self.tableView.contentSize.height-1, 1, 1) animated:YES];
        
		typeof(*self) *weakSelf = self;
		void (^progress)(CGFloat progress) = ^(CGFloat progress) {
			NSParameterAssert([NSThread isMainThread]);
			typeof(*self) *strongSelf = weakSelf;
			if (strongSelf)
			{
                weakSelf.downloadProgress = progress;
                KATGDownloadEpisodeCell *downloadCell = (KATGDownloadEpisodeCell *)[strongSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:KATGShowDetailsSectionDownload]];
                downloadCell.progress = progress;
                downloadCell.state = KATGDownloadEpisodeCellStateDownloading;
			}
		};
		self.downloadToken = [[KATGAudioDownloadManager sharedManager] downloadEpisodeAudio:self.show progress:progress completion:^(NSError *error) {
            if(!error) {
                if(self.view.window == nil || [[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
                    UILocalNotification *ntfy = [[UILocalNotification alloc] init];
                    ntfy.userInfo = @{@"show": self.show.episode_id};
                    ntfy.alertBody = [NSString stringWithFormat:@"Show \"%@\" was downloaded", self.show.title];
                    [[UIApplication sharedApplication] presentLocalNotificationNow:ntfy];
                }
                self.downloadToken = nil;
            }
            else {
                [UIAlertView errorWithTitle:@"Download error" error:error];
            }
            [self updateControlStates];
			NSParameterAssert([NSThread isMainThread]);
			typeof(*self) *strongSelf = weakSelf;
			if (strongSelf)
			{
				strongSelf.shouldReloadDownload = true;
                [strongSelf queueReload];
			}
		}];
        self.downloadToken.viewController = self;
	}
	else if (self.downloadToken && ![self.show.downloaded boolValue])
	{
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Download in progress"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Dismiss"
                                                   destructiveButtonTitle:@"Cancel download"
                                                        otherButtonTitles:nil];
		[actionSheet showInView:self.view];
	}
    else if([self.show.downloaded boolValue]) {
        if([[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying) {
            [[[UIAlertView alloc] initWithTitle:@"KATG"
                                        message:@"You can't remove downloaded media while playing."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            return;
        }
        [[KATGAudioDownloadManager sharedManager] removeDownloadedEpisodeAudio:self.show];
        [[KATGPlaybackManager sharedManager] stop];
        self.downloadProgress = 0;
        [self.tableView reloadData];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.destructiveButtonIndex)
	{
		if (self.downloadToken)
		{
			NSParameterAssert(self.downloadToken);
			[[KATGAudioDownloadManager sharedManager] cancelDownloadToken:self.downloadToken];
            self.downloadToken = nil;
			self.shouldReloadDownload = true;
            [self queueReload];
            [self updateControlStates];
		}
	}
}

#pragma mark - Reachability

- (void)reachabilityReturned:(NSNotification *)note
{
	NSParameterAssert([NSThread isMainThread]);
	[[KATGDataStore sharedStore] downloadEpisodeDetails:self.show.episode_id];
}


- (void)configureTopBar
{
	if ([[KATGPlaybackManager sharedManager] currentShow] &&
        [[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying &&
        ![[[KATGPlaybackManager sharedManager] currentShow] isEqual:self.show])
	{
        if([self.tableView viewWithTag:1313])
            return;
		UIButton *nowPlayingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nowPlayingButton setImage:[UIImage imageNamed:@"NowPlaying.png"] forState:UIControlStateNormal];
		nowPlayingButton.frame = CGRectMake(0.0f, -48.0f, 320.0f, 48.0f);
		[nowPlayingButton addTarget:self action:@selector(showNowPlayingEpisode) forControlEvents:UIControlEventTouchUpInside];
        nowPlayingButton.tag = 1313;
        
        [self.tableView addSubview:nowPlayingButton];
        UIEdgeInsets contentInsets = self.tableView.contentInset;
        contentInsets.top += 48;
        self.tableView.contentInset = contentInsets;
        [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y-48) animated:NO];
	}
	else
	{
        UIView *v = [self.tableView viewWithTag:1313];
        if(v) {
            [v removeFromSuperview];
            UIEdgeInsets contentInsets = self.tableView.contentInset;
            contentInsets.top -= 48;
            self.tableView.contentInset = contentInsets;
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
