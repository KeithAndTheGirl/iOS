//
//  KATGYoutubeDetails.h
//  KATG
//
//  Created by Nicolas Rostov on 23.12.13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KATGYoutubeDetails : UIViewController {
    IBOutlet UIWebView *webView;
    IBOutlet UILabel *dateLabel;
    IBOutlet UILabel *nameLabel;
    IBOutlet UIButton *closeButton;
    IBOutlet UIView *spinnerView;
}

@property (nonatomic, strong) NSDictionary *dataDictionary;
@property (nonatomic, strong) NSDictionary *npInfoRemember;

-(IBAction)closeAction:(id)sender;

@end
