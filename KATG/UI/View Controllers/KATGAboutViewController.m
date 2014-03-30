//
//  KATGAboutViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 31.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGAboutViewController.h"
#import "KATGPlaybackManager.h"
#import "KATGWebViewController.h"

@implementation KATGAboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    scrollView.contentSize = scrollView.frame.size;
    scrollView.frame = self.view.bounds;
    scrollView.contentInset = UIEdgeInsetsMake(20, 0, 56, 0);
    scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(20, 0, 56, 0);
    scrollView.contentOffset = CGPointMake(0, -20);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
}

#pragma mark GlobalPlayState
-(void)registerStateObserver {
    [[KATGPlaybackManager sharedManager] addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self configureNavBar];
}

-(void)unregisterStateObserver {
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
//            [nowPlayingButton addTarget:self.controller action:@selector(nowPlaying:) forControlEvents:UIControlEventTouchUpInside];
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
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.facebook.com/16492114957"]];
}

-(IBAction)twitterAction:(id)sender {
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://user?id=14438295"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?id=14438295"]];
    else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"http://twitter.com/keithandthegirl"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/keithandthegirl"]];
}

-(IBAction)keithAction:(id)sender {
    KATGWebViewController *webCtl = [[KATGWebViewController alloc] init];
    webCtl.urlString = @"http://www.keithandthegirl.com/hosts.aspx#keith";
    [self presentViewController:webCtl animated:YES completion:nil];
}

-(IBAction)chemdaAction:(id)sender {
    KATGWebViewController *webCtl = [[KATGWebViewController alloc] init];
    webCtl.urlString = @"http://www.keithandthegirl.com/hosts.aspx#chemda";
    [self presentViewController:webCtl animated:YES completion:nil];
}

-(IBAction)guideAction:(id)sender {
    KATGWebViewController *webCtl = [[KATGWebViewController alloc] init];
    webCtl.urlString = @"http://ultimatepodcastingguide.com/";
    [self presentViewController:webCtl animated:YES completion:nil];
}

@end
