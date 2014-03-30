//
//  KATGAboutViewController.h
//  KATG
//
//  Created by Nicolas Rostov on 31.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KATGAboutViewController : UIViewController {
    IBOutlet UIScrollView *scrollView;
}

-(IBAction)facebookAction:(id)sender;
-(IBAction)twitterAction:(id)sender;
-(IBAction)keithAction:(id)sender;
-(IBAction)chemdaAction:(id)sender;
-(IBAction)guideAction:(id)sender;

@end
