//
//  KATGAlert.h
//  KATG
//
//  Created by Nicolas Rostov on 24.09.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface UIAlertView (KATGAlert)

+ (void)errorWithTitle:(NSString *)title
                 error:(NSError *)error;

@end
