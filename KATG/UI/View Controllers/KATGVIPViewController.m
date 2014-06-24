//
//  KATGVIPViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 25.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGVIPViewController.h"

@implementation KATGVIPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.emailLabel.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"KATG_EMAIL"];
}

-(IBAction)logoutAction:(id)sender {
    [KATGVipLoginViewController logout];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [KATGUtil alertWithTitle:@"KATG VIP" message:@"Logout success"];
}

@end
