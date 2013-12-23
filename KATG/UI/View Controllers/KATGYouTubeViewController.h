//
//  KATGYouTubeViewController.h
//  KATG
//
//  Created by Nicolas Rostov on 23.12.13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KATGYouTubeViewController : UIViewController {
    IBOutlet UIWebView *webView;
    IBOutlet UILabel *dateLabel;
    IBOutlet UILabel *nameLabel;
    IBOutlet UIButton *closeButton;
}

@property (nonatomic, strong) NSDictionary *dataDictionary;

-(IBAction)closeAction:(id)sender;

@end
