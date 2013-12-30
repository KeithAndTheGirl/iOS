//
//  KATGYouTubeViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 23.12.13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGYouTubeViewController.h"
#import "KATGPlaybackManager.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation KATGYouTubeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    closeButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [closeButton.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [closeButton.layer setBorderWidth:0.5];
    [closeButton.layer setCornerRadius:4];
    
    if([self canPerformAction:@selector(setNeedsStatusBarAppearanceUpdate) withSender:self])
        [self setNeedsStatusBarAppearanceUpdate];
    
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    
    if ([[KATGPlaybackManager sharedManager] state] == KATGAudioPlayerStatePlaying) {
		[[KATGPlaybackManager sharedManager] pause];
	}
}

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                break;
            default:
                break;
        }
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.npInfoRemember = [[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo];
    NSMutableDictionary *episodeInfo = [NSMutableDictionary dictionary];
	episodeInfo[MPMediaItemPropertyArtist] = @"Keith and The Girl";
	episodeInfo[MPMediaItemPropertyPodcastTitle] = @"Keith and The Girl";
	episodeInfo[MPMediaItemPropertyMediaType] = @(MPMediaTypeAnyVideo);
		episodeInfo[MPMediaItemPropertyTitle] = self.dataDictionary[@"title"];
		episodeInfo[MPMediaItemPropertyPlaybackDuration] = self.dataDictionary[@"duration"];
	UIImage *image = [UIImage imageNamed:@"iTunesArtwork"];
	if (image)
	{
		MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
		if (artwork)
		{
			episodeInfo[MPMediaItemPropertyArtwork] = artwork;
		}
	}
	[[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:episodeInfo];
    
    webView.allowsInlineMediaPlayback=YES;
    webView.mediaPlaybackRequiresUserAction=NO;
    webView.mediaPlaybackAllowsAirPlay=YES;
    webView.scrollView.bounces=NO;
    
    NSString *linkObj= [NSString stringWithFormat:@"http://www.youtube.com/v/%@", self.dataDictionary[@"id"]];
    NSLog(@"linkObj1_________________%@",linkObj);
    NSString *embedHTML = @"\
    <html><head>\
    <style type=\"text/css\">\
    body {\
    background-color: black;color: black;}\\</style>\\</head><body style=\"margin:0\">\\<embed webkit-playsinline id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" \\width=\"320\" height=\"320\"></embed>\\</body></html>";
    
    NSString *html = [NSString stringWithFormat:embedHTML, linkObj];
    [webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://youtube.com"]];

    nameLabel.text = self.dataDictionary[@"title"];
    dateLabel.text = self.dataDictionary[@"recorded"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)closeAction:(id)sender {
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	[[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:self.npInfoRemember];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {

}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

@end
