//
//  KATGScheduleViewController.h
//  KATG
//
//  Created by Nicolas Rostov on 30.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KATGScheduleViewController : UIViewController <NSFetchedResultsControllerDelegate> {
    IBOutlet UITableView    *tableView;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

-(void)registerStateObserver;
-(void)unregisterStateObserver;

@end
