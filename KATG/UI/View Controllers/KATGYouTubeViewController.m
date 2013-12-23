//
//  KATGYouTubeViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 23.12.13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGYouTubeViewController.h"

@implementation KATGYouTubeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    closeButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [closeButton.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
    [closeButton.layer setBorderWidth:0.5];
    [closeButton.layer setCornerRadius:4];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)closeAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setDataDictionary:(NSDictionary *)dataDictionary {
    _dataDictionary = dataDictionary;
    
    webView.allowsInlineMediaPlayback=YES;
    webView.mediaPlaybackRequiresUserAction=NO;
    webView.mediaPlaybackAllowsAirPlay=YES;
    webView.scrollView.bounces=NO;
    
    NSString *linkObj= [NSString stringWithFormat:@"http://www.youtube.com/v/%@", dataDictionary[@"id"]];
    NSLog(@"linkObj1_________________%@",linkObj);
    NSString *embedHTML = @"\
    <html><head>\
    <style type=\"text/css\">\
    body {\
    background-color: black;color: black;}\\</style>\\</head><body style=\"margin:0\">\\<embed webkit-playsinline id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" \\width=\"320\" height=\"320\"></embed>\\</body></html>";
    
    NSString *html = [NSString stringWithFormat:embedHTML, linkObj];
    [webView loadHTMLString:html baseURL:nil];
    
    nameLabel.text = dataDictionary[@"title"];
    dateLabel.text = dataDictionary[@"recorded"];
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
