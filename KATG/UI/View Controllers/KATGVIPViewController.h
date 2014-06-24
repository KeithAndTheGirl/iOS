//
//  KATGVIPViewController.h
//  KATG
//
//  Created by Nicolas Rostov on 25.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KATGVipLoginViewController.h"
#import "KATGUtil.h"

@interface KATGVIPViewController : UIViewController

@property (nonatomic, strong) IBOutlet UILabel *emailLabel;

-(IBAction)logoutAction:(id)sender;

@end
