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
#import "KATGShowViewController.h"
#import "KATGShow.h"

@implementation KATGAboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"About";
    scrollView.contentSize = backImageView.frame.size;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self registerStateObserver];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unregisterStateObserver];
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
		UIView *v = [scrollView viewWithTag:1313];
        if(!v) {
            UIButton *nowPlayingButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [nowPlayingButton setImage:[UIImage imageNamed:@"NowPlaying.png"] forState:UIControlStateNormal];
            nowPlayingButton.frame = CGRectMake(0.0f, -48.0f, 320.0f, 48.0f);
            [nowPlayingButton addTarget:self action:@selector(showNowPlayingEpisode) forControlEvents:UIControlEventTouchUpInside];
            nowPlayingButton.tag = 1313;
            
            [scrollView addSubview:nowPlayingButton];
            UIEdgeInsets contentInsets = scrollView.contentInset;
            contentInsets.top += 48;
            scrollView.contentInset = contentInsets;
            [scrollView setContentOffset:CGPointMake(0, scrollView.contentOffset.y-48) animated:NO];
        }
	}
	else {
        UIView *v = [scrollView viewWithTag:1313];
        if(v) {
            [v removeFromSuperview];
            UIEdgeInsets contentInsets = scrollView.contentInset;
            contentInsets.top -= 48;
            scrollView.contentInset = contentInsets;
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
