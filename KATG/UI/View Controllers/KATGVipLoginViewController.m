//
//  KATGVipLoginViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 28.04.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGVipLoginViewController.h"
#import "KATGPlaybackManager.h"
#import "AFNetworking.h"

@implementation KATGVipLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    loginField.text = [def valueForKey:@"KATG_EMAIL"];
    passwordField.text = [def valueForKey:@"KATG_PASS"];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [loginField becomeFirstResponder];
}

-(BOOL)isValidEmail:(NSString *)checkString {
    NSString *emailRegex = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

-(void)showAlert:(NSString*)alert {
    [[[UIAlertView alloc] initWithTitle:@"KATG VIP Login"
                                message:alert
                               delegate:nil
                      cancelButtonTitle:@"Ok"
                      otherButtonTitles:nil]
     show];
}

#pragma actions
-(IBAction)loginAction:(id)sender {
    if(![loginField.text length]) {
        [self showAlert:@"Please enter your email"];
        [loginField becomeFirstResponder];
        return;
    }
    if(![passwordField.text length]) {
        [self showAlert:@"Please enter your password"];
        [passwordField becomeFirstResponder];
        return;
    }
    if(![self isValidEmail:loginField.text]) {
        [self showAlert:@"Please enter correct email"];
        [loginField becomeFirstResponder];
        return;
    }
    
    NSString *login = loginField.text;
    NSString *pass = passwordField.text;
    
    AFHTTPRequestOperationManager *manager =
    [[AFHTTPRequestOperationManager alloc] initWithBaseURL:
     [NSURL URLWithString:@"https://www.keithandthegirl.com/api/v2/"]];
    [manager POST:@"vip/authenticateuser/"
       parameters:@{@"email": login, @"password": pass}
      cachePolicy:NSURLRequestReloadIgnoringCacheData
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"%@", responseObject);
              if([responseObject[@"Error"] integerValue] > 0) {
                  passwordField.text = @"";
                  [self showAlert:responseObject[@"Message"]];
              }
              else {
                  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
                  [def setObject:responseObject[@"KatgVip_key"] forKey:KATG_PLAYBACK_KEY];
                  [def setObject:responseObject[@"KatgVip_uid"] forKey:KATG_PLAYBACK_UID];
                  [def setObject:login forKey:@"KATG_EMAIL"];
                  [def setObject:pass forKey:@"KATG_PASS"];
                  [def synchronize];
                  [self dismissViewControllerAnimated:YES
                                           completion:^{
                                               self.completion();
                                           }];
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"%@", error);
          }];
}

-(IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 
                             }];
}

+(void)logout {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def removeObjectForKey:KATG_PLAYBACK_KEY];
    [def removeObjectForKey:KATG_PLAYBACK_UID];
}

@end
