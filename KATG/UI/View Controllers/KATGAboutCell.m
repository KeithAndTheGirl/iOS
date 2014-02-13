//
//  KATGAboutCell.m
//  KATG
//
//  Created by Nicolas Rostov on 12/9/13.
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

#import "KATGAboutCell.h"
#import "KATGContentContainerView.h"
#import "KATGScheduleItemTableViewCell.h"
#import "KATGPlaybackManager.h"

@implementation KATGAboutCell

-(void)awakeFromNib {
    [content removeFromSuperview];
    
    scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    [self.contentView addSubview:scrollView];
    [scrollView addSubview:content];
    scrollView.contentSize = content.frame.size;
    scrollView.autoresizingMask = 15;
    self.autoresizingMask = 15;
    scrollView.scrollsToTop = NO;
    for(UIScrollView *v in content.subviews) {
        if([v isKindOfClass:[UITextView class]])
            v.scrollsToTop = NO;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.) {
        scrollView.contentInset = UIEdgeInsetsMake(20, 0, 56, 0);
        scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(20, 0, 56, 0);
        scrollView.contentOffset = CGPointMake(0, -20);
    }
    else {
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 56, 0);
        scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 56, 0);
    }    
}

-(void)layoutSubviews {
    [super layoutSubviews];
    scrollView.frame = self.bounds;
    content.frame = CGRectMake(0, 0, content.frame.size.width, content.frame.size.height);
}

- (void)prepareForReuse {
	[super prepareForReuse];
    NSLog(@"%@", NSStringFromCGRect(scrollView.frame));
}

-(void)willShow {
    scrollView.scrollsToTop = YES;
    [[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self configureNavBar];
}
-(void)willHide {
    scrollView.scrollsToTop = NO;
	[[KATGPlaybackManager sharedManager] removeObserver:self forKeyPath:@"state"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self configureNavBar];
}

- (void)configureNavBar
{
	if ([[KATGPlaybackManager sharedManager] currentShow] &&
        [[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying)
	{
		UIView *v = [scrollView viewWithTag:1313];
        if(!v) {
            UIButton *nowPlayingButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [nowPlayingButton setImage:[UIImage imageNamed:@"NowPlaying.png"] forState:UIControlStateNormal];
            nowPlayingButton.frame = CGRectMake(0.0f, -48.0f, 320.0f, 48.0f);
            [nowPlayingButton addTarget:self.controller action:@selector(nowPlaying:) forControlEvents:UIControlEventTouchUpInside];
            nowPlayingButton.tag = 1313;
            
            [scrollView addSubview:nowPlayingButton];
            UIEdgeInsets contentInsets = scrollView.contentInset;
            contentInsets.top += 48;
            scrollView.contentInset = contentInsets;
            [scrollView setContentOffset:CGPointMake(0, scrollView.contentOffset.y-48) animated:NO];
        }
	}
	else
	{
        UIView *v = [scrollView viewWithTag:1313];
        if(v) {
            [v removeFromSuperview];
            UIEdgeInsets contentInsets = scrollView.contentInset;
            contentInsets.top -= 48;
            scrollView.contentInset = contentInsets;
        }
	}
}

#pragma mark Actions
-(IBAction)facebookAction:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://facebook.com/keithandthegirl"]];
}

-(IBAction)twitterAction:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/keithandthegirl"]];
}

-(IBAction)keithAction:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.keithandthegirl.com/hosts.aspx#keith"]];
}

-(IBAction)chemdaAction:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.keithandthegirl.com/hosts.aspx#chemda"]];
}

-(IBAction)guideAction:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://ultimatepodcastingguide.com/"]];
}

@end
