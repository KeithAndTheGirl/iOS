//
//  KATGDownloadEpisodeCell.m
//  KATG
//
//  Created by Tim Donnelly on 4/10/13.
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

#import "KATGDownloadEpisodeCell.h"
#import "KATGButton.h"
#import "KATGDownloadProgressView.h"

@interface KATGDownloadEpisodeCell ()
@property (strong, nonatomic) KATGButton *downloadButton;
@property (strong, nonatomic) KATGDownloadProgressView *downloadProgressView;
@end

@implementation KATGDownloadEpisodeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) 
	{
		self.showTopRule = YES;
		
		_downloadButton = [KATGButton new];
		_downloadButton.backgroundColor = [UIColor colorWithRed:243./255 green:245./255 blue:246./255 alpha:1];
        
		[_downloadButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		_downloadButton.titleLabel.shadowOffset = CGSizeMake(0.0f, 0.0f);
        
        [_downloadButton setTintColor:[UIColor blackColor]];
        _downloadButton.titleLabel.textColor = [UIColor blackColor];
		[_downloadButton addTarget:self action:@selector(downloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		
		_downloadProgressView = [[KATGDownloadProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 28.0f, 28.0f)];
		_downloadButton.decorationView = _downloadProgressView;
		
		[self.contentView addSubview:self.downloadButton];
		self.state = KATGDownloadEpisodeCellStateActive;
	}
	return self;
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	self.state = KATGDownloadEpisodeCellStateActive;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	self.downloadButton.frame = CGRectMake(50.0f, 10.0f, self.contentView.bounds.size.width - 100.0f, self.contentView.bounds.size.height - 20.0f);
}

- (void)downloadButtonPressed:(id)sender
{
	[self.delegate downloadButtonPressed:self];
}

- (void)setState:(KATGDownloadEpisodeCellState)state
{
	if (state == _state)
	{
		return;
	}
	_state = state;
	switch (_state) 
	{
		case KATGDownloadEpisodeCellStateUnknown:
			
			break;
		case KATGDownloadEpisodeCellStateActive:
			self.downloadButton.enabled = YES;
			_downloadProgressView.currentState = KATGDownloadProgressViewStateNotDownloaded;
			[self.downloadButton setTitle:@"Download To Listen Later" forState:UIControlStateNormal];
            [self.downloadButton setImage:[UIImage imageNamed:@"DownloadIcon.png"] forState:UIControlStateNormal];
            self.downloadButton.imageEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 0);
			break;
		case KATGDownloadEpisodeCellStateDownloading:
			self.downloadButton.enabled = YES;
			_downloadProgressView.currentState = KATGDownloadProgressViewStateDownloading;
			[self.downloadButton setTitle:@"Cancel Download" forState:UIControlStateNormal];
            [self.downloadButton setImage:nil forState:UIControlStateNormal];
			break;
		case KATGDownloadEpisodeCellStateDownloaded:
			self.downloadButton.enabled = YES;
			_downloadProgressView.currentState = KATGDownloadProgressViewStateDownloaded;
            [self.downloadButton setTitle:@"Delete this download" forState:UIControlStateNormal];
            [self.downloadButton setImage:nil forState:UIControlStateNormal];
			break;
		case KATGDownloadEpisodeCellStateDisabled:
			self.downloadButton.enabled = NO;
			_downloadProgressView.currentState = KATGDownloadProgressViewStateNotDownloaded;
            [self.downloadButton setImage:nil forState:UIControlStateNormal];            
			[self.downloadButton setTitle:@"Download Not Available" forState:UIControlStateNormal];
			break;
		default:
			break;
	}
	[self setNeedsLayout];
}

- (void)setProgress:(CGFloat)progress
{
	if (self.state != KATGDownloadEpisodeCellStateDownloading)
	{
		return;
	}
	[self.downloadButton setTitle:[NSString stringWithFormat:@"Downloading (%2.0f%%)", progress * 100] forState:UIControlStateNormal];
	self.downloadProgressView.downloadProgress = progress;
}

@end
