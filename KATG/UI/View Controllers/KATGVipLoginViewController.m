//
//  KATGVipLoginViewController.m
//  KATG
//
//  Created by Nicolas Rostov on 28.04.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGVipLoginViewController.h"
#import "KATGPlaybackManager.h"

@implementation KATGVipLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    loginField.text = [[def valueForKey:KATG_PLAYBACK_USERNAME_KEY]
                       stringByReplacingOccurrencesOfString:@"%%40"
                       withString:@"@"];
    passwordField.text = [def valueForKey:KATG_PLAYBACK_PASSWORD_KEY];
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
    
    NSString *login = [loginField.text stringByReplacingOccurrencesOfString:@"@" withString:@"%40"];
    NSString *pass = passwordField.text;
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setObject:login forKey:KATG_PLAYBACK_USERNAME_KEY];
    [def setObject:pass forKey:KATG_PLAYBACK_PASSWORD_KEY];
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 self.completion();
                             }];
}

-(IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 
                             }];
}

@end
