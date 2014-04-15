//
//  KATGListSettingsController.h
//  KATG
//
//  Created by Nicolas Rostov on 16.04.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KATGDataStore.h"
#import "KATGShow.h"

#define EPISODES_SORT_RECENTLY_LISTENED @"EPISODES_SORT_RECENTLY_LISTENED"
#define EPISODES_FILTER_DOWNLOADED @"EPISODES_FILTER_DOWNLOADED"

@interface KATGListSettingsController : UIViewController {
    IBOutlet UIButton       *doneButton;
    IBOutlet UITableView    *tableView;
}

@property (nonatomic, strong) NSArray *episodes;
@property (nonatomic, strong) NSMutableArray *downloadedEpisodes;
@property (nonatomic, strong) NSMutableArray *selectedEpisodes;

-(IBAction)doneAction:(id)sender;
-(IBAction)cancelAction:(id)sender;

@end
