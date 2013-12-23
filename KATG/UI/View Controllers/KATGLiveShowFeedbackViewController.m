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

#define TEXTVIEW_PLACEHOLDER @"Comment"

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
    
    _messagesTextView.textColor = [UIColor lightGrayColor];
    _messagesTextView.text = TEXTVIEW_PLACEHOLDER;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    if([self.nameTextField.text length] > 0) {
        [self.messagesTextView becomeFirstResponder];
    }
    else {
        [self.nameTextField becomeFirstResponder];
    }
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
	NSString *message = [self.messagesTextView.text isEqualToString:TEXTVIEW_PLACEHOLDER]?@"":self.messagesTextView.text;
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
    self.sendButton.enabled = NO;
	__weak typeof(*self) *weakSelf = self;
	[[KATGDataStore sharedStore] submitFeedback:name location:location comment:message completion:^(NSError *error) {
		__weak typeof(*weakSelf) *strongSelf = weakSelf;
        weakSelf.sendButton.enabled = YES;
		if (strongSelf)
		{
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				if (error)
				{
					UIAlertView *alertView = [[UIAlertView alloc]
                                              initWithTitle:NSLocalizedString(@"Error", nil)
                                              message:[error localizedDescription]
                                              //NSLocalizedString(@"There was an error sending feedback, please check your connection and try again.", nil)
                                              delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
					[alertView show];
				}
				else
				{
					strongSelf.messagesTextView.text = @"";
                    [strongSelf textViewShouldEndEditing:strongSelf.messagesTextView];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"Feedback was sent successfully.", nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
					[alertView show];
					UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"feedback sent", nil));
				}
				strongSelf.nameTextField.enabled = YES;
				strongSelf.locationTextField.enabled = YES;
				strongSelf.messagesTextView.editable = YES;
			});
		}
	}];
}

#pragma mark UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (textView.textColor == [UIColor lightGrayColor]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if([textView.text length] == 0) {
        _messagesTextView.textColor = [UIColor lightGrayColor];
        _messagesTextView.text = TEXTVIEW_PLACEHOLDER;
    }
    return YES;
}

@end
