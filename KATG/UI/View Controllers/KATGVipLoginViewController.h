//
//  KATGVipLoginViewController.h
//  KATG
//
//  Created by Nicolas Rostov on 28.04.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KATGVipLoginViewController : UIViewController {
    IBOutlet UITextField *loginField;
    IBOutlet UITextField *passwordField;
}

@property (nonatomic, copy) void (^completion)();

-(IBAction)loginAction:(id)sender;
-(IBAction)cancelAction:(id)sender;
+(void)logout;

@end
