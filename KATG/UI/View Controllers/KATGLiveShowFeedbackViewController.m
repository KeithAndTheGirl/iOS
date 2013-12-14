//
//  KATGLiveShowFeedbackViewController.m
//  KATG
//
//  Created by Timothy Donnelly on 5/2/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGLiveShowFeedbackViewController.h"
#import "KATGButton.h"
#import "KATGDataStore.h"
#import "KATGContentContainerView.h"
#import <QuartzCore/QuartzCore.h>

@implementation KATGLiveShowFeedbackViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.)
        self.view.layer.sublayerTransform = CATransform3DMakeTranslation(0, -20, 0);
	
	[_nameTextField.layer setBorderColor:[[UIColor colorWithWhite:0.5 alpha:0.75] CGColor]];
    [_nameTextField.layer setBorderWidth:0.5];
    [_nameTextField.layer setCornerRadius:4];
	
	[_locationTextField.layer setBorderColor:[[UIColor colorWithWhite:0.5 alpha:0.75] CGColor]];
    [_locationTextField.layer setBorderWidth:0.5];
    [_locationTextField.layer setCornerRadius:4];
	
	[_messagesTextView.layer setBorderColor:[[UIColor colorWithWhite:0.5 alpha:0.75] CGColor]];
    [_messagesTextView.layer setBorderWidth:0.5];
    [_messagesTextView.layer setCornerRadius:4];
    
    _nameTextField.layer.sublayerTransform = CATransform3DMakeTranslation(4, 0, 0);
    _locationTextField.layer.sublayerTransform = CATransform3DMakeTranslation(4, 0, 0);
    _messagesTextView.layer.sublayerTransform = CATransform3DMakeTranslation(2, 0, 0);
    
    _nameTextField.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"name"];
    _locationTextField.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"location"];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.messagesTextView becomeFirstResponder];
}

- (IBAction)close:(id)sender
{
	if (self.presentingViewController)
	{
		[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
	}
	else
	{
		[self.delegate closeLiveShowFeedbackViewController:self];
	}
}

- (IBAction)send:(id)sender
{
	NSString *name = self.nameTextField.text;
	NSString *location = self.locationTextField.text;
	NSString *message = self.messagesTextView.text;
	if (![message length])
	{
		return;
	}
	if (name)
	{
		[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"name"];
	}
	if (location)
	{
		[[NSUserDefaults standardUserDefaults] setObject:location forKey:@"location"];
	}
	self.nameTextField.enabled = NO;
	self.locationTextField.enabled = NO;
	self.messagesTextView.editable = NO;
	__weak typeof(*self) *weakSelf = self;
	[[KATGDataStore sharedStore] submitFeedback:name location:location comment:message completion:^(NSError *error) {
		__weak typeof(*weakSelf) *strongSelf = weakSelf;
		if (strongSelf)
		{
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				if (error)
				{
					UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"There was an error sending feedback, please check your connection and try again.", nil) delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
					[alertView show];
				}
				else
				{
					strongSelf.messagesTextView.text = @"";
					UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"feedback sent", nil));
				}
				strongSelf.nameTextField.enabled = YES;
				strongSelf.locationTextField.enabled = YES;
				strongSelf.messagesTextView.editable = YES;
			});
		}
	}];
}

@end
