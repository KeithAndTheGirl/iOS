//
//  KATGEpisodesViewController.h
//  KATG
//
//  Created by Nicolas Rostov on 27.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KATGSeries.h"
#import "KATGShow.h"
#import "KATGDataStore.h"
#import "KATGShowView.h"
#import "KATGShowViewController.h"

@interface KATGEpisodesViewController : UIViewController <NSFetchedResultsControllerDelegate> {
    IBOutlet UITableView    *tableView;
    IBOutlet UIImageView    *coverImage;
    IBOutlet UILabel        *titleLabel;
    IBOutlet UILabel        *descLabel;
    IBOutlet UIButton       *backButton;
    IBOutlet UIButton       *detailsButton;
}

@property (nonatomic, strong) KATGSeries *series;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

-(IBAction)backAction:(id)sender;
-(IBAction)detailsAction:(id)sender;

@end
