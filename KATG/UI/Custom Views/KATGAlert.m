//
//  KATGAlert.m
//  KATG
//
//  Created by Nicolas Rostov on 24.09.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGAlert.h"

static NSError *alertError;

@interface AlertSingleton:NSObject <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

@end

@implementation AlertSingleton

+ (instancetype)sharedInstance {
    static AlertSingleton *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AlertSingleton alloc] init];
    });
    return sharedInstance;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1 && [MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailView = [[MFMailComposeViewController alloc] init];
        [mailView setSubject:[NSString stringWithFormat:@"KATG iOS app v%@ error", APP_VERSION]];
        [mailView setToRecipients:@[@"support@keithandthegirl.com"]];
        NSString *message = [NSString stringWithFormat:@"\n\nThe KATG app just had the following error:\n%@\nStack trace:\n%@", alertError, [NSThread callStackSymbols]];
        [mailView setMessageBody:message isHTML:NO];
        mailView.mailComposeDelegate = [AlertSingleton sharedInstance];
        UIViewController *mainController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        [mainController presentViewController:mailView animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation UIAlertView (KATGAlert)

+ (void)errorWithTitle:(NSString *)title error:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"Error occured: %@\nWould you like to send report?", [error localizedDescription]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    alert.delegate = [AlertSingleton sharedInstance];
    [alert show];
    alertError = error;
}

@end

