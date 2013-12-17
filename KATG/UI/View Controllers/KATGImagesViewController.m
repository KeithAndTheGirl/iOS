//
//  KATGImagesViewController.m
//  KATG
//
//  Created by Tim Donnelly on 3/9/13.
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

#import "KATGImagesViewController.h"
#import "KATGFullScreenImageCell.h"
#import "KATGImageCache.h"
#import "KATGImage.h"
#import "UICollectionView+TDAdditions.h"
#import "KATGButton.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define IMAGE_GAP 10.0f

static NSString *fullScreenImageCellIdentifier = @"fullScreenImageCellIdentifier";

@interface KATGImagesViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, KATGFullScreenImageCellDelegate, UIActionSheetDelegate>
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UIButton *saveButton;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIActionSheet *actionSheet;
@end

@implementation KATGImagesViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.accessibilityViewIsModal = YES;
	
	self.view.backgroundColor = [UIColor clearColor];
	
	self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
	self.backgroundView.backgroundColor = [UIColor blackColor];
	self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:self.backgroundView];
	
	UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
	flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	CGRect collectionViewRect = self.view.bounds;
	collectionViewRect.origin.x -= (IMAGE_GAP/2.0f);
	collectionViewRect.size.width += IMAGE_GAP;
	
	self.collectionView = [[UICollectionView alloc] initWithFrame:collectionViewRect collectionViewLayout:flowLayout];
	self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.collectionView.delegate = self;
	self.collectionView.pagingEnabled = YES;
	self.collectionView.dataSource = self;
	self.collectionView.showsHorizontalScrollIndicator = NO;
	self.collectionView.showsVerticalScrollIndicator = NO;
	[self.collectionView registerClass:[KATGFullScreenImageCell class] forCellWithReuseIdentifier:fullScreenImageCellIdentifier];
	[self.view addSubview:self.collectionView];
	
	self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(250.0f, 20.0f, 60.0f, 36.0f)];
    _closeButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [_closeButton.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [_closeButton.layer setBorderWidth:0.5];
    [_closeButton.layer setCornerRadius:4];
	[_closeButton setTitle:@"Done" forState:UIControlStateNormal];
	_closeButton.contentEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 4.0f, 0.0f);
	[_closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_closeButton];
	
	self.saveButton = [[UIButton alloc] initWithFrame:CGRectMake(10.0f, 20.0f, 60.0f, 36.0f)];
    _saveButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [_saveButton.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [_saveButton.layer setBorderWidth:0.5];
    [_saveButton.layer setCornerRadius:4];
	[_saveButton setTitle:@"Save" forState:UIControlStateNormal];
	_saveButton.contentEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 4.0f, 0.0f);
	[_saveButton addTarget:self action:@selector(disclosureButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_saveButton];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0f, 370.0f, 310.0f, 56.0f)];
    self.titleLabel.numberOfLines = 4;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.titleLabel];
}

- (void)transitionFromImage:(KATGImage *)image inImageView:(UIImageView *)imageView animations:(void(^)())animations completion:(void(^)())completion;
{
	CGSize imageSize = imageView.image.size;
	if (!imageView.image)
	{
		imageSize = self.view.bounds.size;
	}
	
	CGRect initialRect = [self.view convertRect:imageView.frame fromView:imageView.superview];
	UIView *transitionContainerView = [[UIView alloc] initWithFrame:initialRect];
	transitionContainerView.clipsToBounds = YES;
	[self.view addSubview:transitionContainerView];
	
	UIImageView *transitionImageView = [[UIImageView alloc] initWithFrame:transitionContainerView.bounds];
	transitionImageView.image = imageView.image;
	transitionImageView.contentMode = UIViewContentModeScaleAspectFill;
	[transitionContainerView addSubview:transitionImageView];
	
	// Transitioning from aspect fill to aspect fit - figure out the new scale
	
	CGFloat imageAspect = imageSize.width / imageSize.height;
	CGFloat screenAspect = self.view.bounds.size.width / self.view.bounds.size.height;
	
	CGRect newImageRect = CGRectZero;
	
	if (imageAspect > screenAspect)
	{
		// scale by width
		newImageRect.size.width = self.view.bounds.size.width;
		newImageRect.size.height = self.view.bounds.size.width / imageAspect;
	}
	else
	{
		newImageRect.size.height = self.view.bounds.size.height;
		newImageRect.size.width = self.view.bounds.size.height * imageAspect;
	}
	
	NSInteger index = [self.images indexOfObject:image];
	[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
	
	self.collectionView.hidden = YES;
	
	self.backgroundView.alpha = 0.0f;

	self.closeButton.alpha = 0.0f;
    self.saveButton.alpha = 0.0f;
    self.titleLabel.alpha = 0.0f;
	[self updateTitleWithImage:image];
	
	[UIView animateWithDuration:0.4f
						  delay:0.0f
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.closeButton.alpha = 1.0f;
                         self.saveButton.alpha = 1.0f;
                         self.titleLabel.alpha = 1.0f;
                         
						 transitionContainerView.frame = self.view.bounds;
						 transitionImageView.bounds = newImageRect;
						 transitionImageView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
						 self.backgroundView.alpha = 1.0f;
						 if (animations)
						 {
							 animations();
						 }
					 } completion:^(BOOL finished) {
						 self.collectionView.hidden = NO;
						 [self setNavigationBarVisible:YES animated:YES];
						 [transitionContainerView removeFromSuperview];
						 if (completion)
						 {
							 completion();
						 }
					 }];
	
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.images count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	KATGFullScreenImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:fullScreenImageCellIdentifier forIndexPath:indexPath];
	cell.imageView.image = nil;
	cell.delegate = self;
	KATGImage *image = self.images[indexPath.row];
	cell.currentImage = image;
	cell.isAccessibilityElement = YES;
	cell.accessibilityLabel = image.title;
	__weak KATGImage *weakImage = image;
	__weak KATGFullScreenImageCell *weakCell = cell;
	[[KATGImageCache imageCache] imageForURL:[NSURL URLWithString:cell.currentImage.media_url] size:CGSizeZero progressHandler:^(float progress) {
		//NSLog(@"Progress %f", progress);
	} completionHandler:^(UIImage *img, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if ([[weakImage objectID] isEqual:[weakCell.currentImage objectID]])
			{
				weakCell.imageView.image = img;
				[weakCell setupImageInScrollView];
				weakCell.activityIndicatorView.hidden = YES;
			}
		});
	}];
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return self.view.bounds.size;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
	return CGSizeMake(IMAGE_GAP/2.0f, self.view.bounds.size.height);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
	return CGSizeMake(IMAGE_GAP/2.0f, self.view.bounds.size.height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	return IMAGE_GAP;
}

#pragma mark - Scrolling

- (void)updateTitle
{
	NSIndexPath *indexPath = [self.collectionView nearestIndexPathForContentOffset:self.collectionView.contentOffset];
	KATGImage *image = self.images[indexPath.row];
	[self updateTitleWithImage:image];
}

- (void)updateTitleWithImage:(KATGImage *)image
{
	self.titleLabel.text = image.title;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	[self setNavigationBarVisible:NO animated:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (decelerate)
	{
		return;
	}
	[self updateTitle];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self updateTitle];
}

#pragma mark -

- (void)setImages:(NSArray *)images
{
	NSAssert([[NSThread currentThread] isMainThread], @"Images must be set on main thread");
	_images = images;
	[self.collectionView reloadData];
}

- (void)close
{
	NSIndexPath *centerIndexPath = [self.collectionView indexPathForItemAtPoint:[self.collectionView convertPoint:self.view.center fromView:self.view.superview]];
	KATGFullScreenImageCell *centerCell = (KATGFullScreenImageCell *)[self.collectionView cellForItemAtIndexPath:centerIndexPath];
	
	UIView *collapseTargetView = [self.delegate imagesViewController:self viewToCollapseIntoForImage:centerCell.currentImage];
	CGRect collapseTargetFrame = [self.view convertRect:collapseTargetView.frame fromView:collapseTargetView.superview];
	
	CGRect initialImageRect = [self.view convertRect:centerCell.imageView.frame fromView:centerCell.imageView.superview];
	
	UIView *transitionContainerView = [[UIView alloc] initWithFrame:self.view.bounds];
	transitionContainerView.clipsToBounds = YES;
	transitionContainerView.backgroundColor = [UIColor clearColor];
	[self.view addSubview:transitionContainerView];
	
	UIImageView *transitionImageView = [[UIImageView alloc] initWithFrame:initialImageRect];
	transitionImageView.image = centerCell.imageView.image;
	transitionImageView.contentMode = UIViewContentModeScaleAspectFit;
	[transitionContainerView addSubview:transitionImageView];
	
	// Transitioning from aspect fit to aspect fill - figure out the new size
	CGFloat imageAspectRatio = centerCell.imageView.image.size.width / centerCell.imageView.image.size.height;
	if (!centerCell.imageView.image)
	{
		imageAspectRatio = 1.0f;
	}
	
	CGFloat newSize = collapseTargetFrame.size.width;
	CGRect newImageBounds = CGRectZero;
	if (imageAspectRatio > 1.0f)
	{
		// scale by height
		newImageBounds.size.height = newSize;
		newImageBounds.size.width = newSize * imageAspectRatio;
	}
	else
	{
		// scale by width
		newImageBounds.size.width = newSize;
		newImageBounds.size.height = newSize / imageAspectRatio;
	}
	
	self.collectionView.hidden = YES;
	[self.view bringSubviewToFront:self.closeButton];
	[self.view bringSubviewToFront:self.saveButton];
	[self setNavigationBarVisible:NO animated:YES];
	
	UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Dismissing image gallery", nil));
	[UIView animateWithDuration:0.4f
						  delay:0.0f
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 
						 self.closeButton.alpha = 0.0f;
						 self.saveButton.alpha = 0.0f;
                         self.titleLabel.alpha = 0.0f;
						 
						 transitionContainerView.frame = collapseTargetFrame;
						 transitionImageView.bounds = newImageBounds;
						 transitionImageView.center = CGPointMake(newSize/2, newSize/2);
						 self.backgroundView.alpha = 0.0f;
						 [self.delegate performAnimationsWhileImagesViewControllerIsClosing:self];
					 } completion:^(BOOL finished) {
						 [transitionContainerView removeFromSuperview];
						 [self.delegate closeImagesViewController:self];
					 }];
	
}

- (void)setNavigationBarVisible:(BOOL)visible animated:(BOOL)animated
{
	if (animated)
	{
		if (visible && self.saveButton.hidden)
		{
			self.closeButton.hidden = NO;
			self.saveButton.hidden = NO;
            self.titleLabel.hidden = NO;
			self.closeButton.alpha = 0.0f;
			self.saveButton.alpha = 0.0f;
            self.titleLabel.alpha = 0.0f;
		}
		
		[UIView animateWithDuration:0.2f
						 animations:^{
							 self.closeButton.alpha = visible ? 1.0f : 0.0f;
							 self.saveButton.alpha = visible ? 1.0f : 0.0f;
                             self.titleLabel.alpha = visible ? 1.0f : 0.0f;
						 } completion:^(BOOL finished) {
							 if (!visible)
							 {
								 self.closeButton.hidden = YES;
								 self.saveButton.hidden = YES;
                                 self.titleLabel.hidden = YES;
							 }
						 }];
	}
	else
	{
		self.closeButton.hidden = !visible;
		self.saveButton.hidden = !visible;
        self.titleLabel.hidden = !visible;
		self.closeButton.alpha = 1.0f;
		self.saveButton.alpha = 1.0f;
        self.titleLabel.alpha = 1.0f;
	}
}

#pragma mark - KATGFullScreenImageCellDelegate

- (void)didTapFullScreenImageCell:(KATGFullScreenImageCell *)cell
{
	[self setNavigationBarVisible:(self.saveButton.hidden) animated:YES];
}

- (BOOL)katg_performAccessibilityEscape
{
	[self close];
	return YES;
}

#pragma mark - Save

- (void)disclosureButtonTapped:(id)sender
{
	self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Save image to camera roll", @""), nil];
	[self.actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSParameterAssert(actionSheet == self.actionSheet);
	self.actionSheet = nil;
	if (actionSheet.cancelButtonIndex == buttonIndex)
	{
		return;
	}
	
	self.navigationItem.leftBarButtonItem.enabled = NO;
	NSIndexPath *indexPath = [self.collectionView nearestIndexPathForContentOffset:self.collectionView.contentOffset];
	KATGImage *image = self.images[indexPath.row];
	[[KATGImageCache imageCache] imageForURL:[NSURL URLWithString:image.media_url] size:CGSizeZero progressHandler:^(float progress) {
		
	} completionHandler:^(UIImage *img, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			ALAssetsLibrary *library = [ALAssetsLibrary new]; 
			[library writeImageToSavedPhotosAlbum:[img CGImage] orientation:(ALAssetOrientation)[img imageOrientation] completionBlock:^(NSURL* assetURL, NSError* error) {
				if (error)
				{
					NSLog(@"%@", error);
				}
				else
				{
					
				}
				self.navigationItem.leftBarButtonItem.enabled = YES;
			}];
		});
	}];
}

@end
