//
//  KATGWebViewController.m
//  KATG
//
//  Created by Timothy Donnelly on 9/24/12.
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

#import "KATGWebViewController.h"

@interface KATGWebViewController ()
@property (nonatomic, strong)UIWebView *webView;
@end

@implementation KATGWebViewController

#pragma mark - Object Life Cycle

- (instancetype)init
{
	self = [super init];
	if (self)
	{
        self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        self.webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        self.webView.scalesPageToFit = YES;
        [self.view addSubview:self.webView];
        
		UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(250.0f, 20.0f, 60.0f, 36.0f)];
        closeButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        [closeButton.layer setBorderColor:[[UIColor colorWithWhite:1 alpha:0.75] CGColor]];
        [closeButton.layer setBorderWidth:0.5];
        [closeButton.layer setCornerRadius:4];
        [closeButton setTitle:@"Close" forState:UIControlStateNormal];
        closeButton.contentEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 4.0f, 0.0f);
        [closeButton addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:closeButton];
	}
	return self;
}

- (void)dealloc
{
	self.webView = nil;
}

#pragma mark - View Life Cycle

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	NSURL *url = [NSURL URLWithString:self.urlString];
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	[self.webView loadRequest:requestObj];
}

- (void)close:(id)sender
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
