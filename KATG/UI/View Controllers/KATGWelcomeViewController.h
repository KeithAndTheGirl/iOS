//
//  KATGWelcomeViewController.h
//  KATG
//
//  Created by Nicolas Rostov on 27.12.13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KATGWelcomeViewController : UIViewController {
    IBOutlet UIScrollView *scroll;
    IBOutlet UIImageView *indicatorsView;
    IBOutlet UIButton *getStartedButton;
}

-(IBAction)startAction:(id)sender;

@end
