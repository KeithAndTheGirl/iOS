//
//  KATGListSettingsController.h
//  KATG
//
//  Created by Nicolas Rostov on 16.04.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

#define EPISODES_SORT_RECENTLY_LISTENED @"EPISODES_SORT_RECENTLY_LISTENED"
#define EPISODES_FILTER_DOWNLOADED @"EPISODES_FILTER_DOWNLOADED"

@interface KATGListSettingsController : UIViewController {
    IBOutlet UIButton       *doneButton;
    IBOutlet UIButton       *cancelButton;
}

-(IBAction)doneAction:(id)sender;
-(IBAction)cancelAction:(id)sender;

@end
