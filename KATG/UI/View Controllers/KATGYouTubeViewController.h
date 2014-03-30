//
//  KATGYoutubeViewController.h
//  KATG
//
//  Created by Nicolas Rostov on 30.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KATGYoutubeViewController : UIViewController {
    IBOutlet UITableView *tableView;
    IBOutlet UIView *spinnerView;
    UIRefreshControl *refreshControl;
    NSArray *channelItems;
}

-(void)reload;

-(void)registerStateObserver;
-(void)unregisterStateObserver;

@end
