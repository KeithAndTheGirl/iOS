//
//  KATGLiveShowFeedbackViewController.h
//  KATG
//
//  Created by Timothy Donnelly on 5/2/13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGViewController.h"

@protocol KATGLiveShowFeedbackViewControllerDelegate;

@interface KATGLiveShowFeedbackViewController : KATGViewController
@property (weak, nonatomic) id<KATGLiveShowFeedbackViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *locationTextField;
@property (weak, nonatomic) IBOutlet UITextView *messagesTextView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

- (IBAction)send:(id)sender;
- (IBAction)close:(id)sender;

@end

@protocol KATGLiveShowFeedbackViewControllerDelegate <NSObject>
- (void)closeLiveShowFeedbackViewController:(KATGLiveShowFeedbackViewController *)liveShowFeedbackViewController;
@end