//
//  KATGEpisodeViewController_iPhone.h
//  KATG
//
//  Created by Timothy Donnelly on 11/12/12.
//  Copyright (c) 2012 Doug Russell. All rights reserved.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  

#import "KATGShowControlsView.h"
#import "KATGUtil.h"
#import "KATGShowPreviewCell.h"

@class KATGShow, KATGShowViewController, KATGShowView;

@protocol KATGShowViewControllerDelegate <NSObject>
- (void)closeShowViewController:(KATGShowViewController *)showViewController;
@end

@interface KATGShowViewController : UIViewController <KATGShowPreviewCellDelegate>

@property (nonatomic, readonly) KATGShow *show;
@property (assign, nonatomic) BOOL needAuth;
@property (nonatomic) NSManagedObjectID	*showObjectID;
@property (weak, nonatomic) id<KATGShowViewControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet UIView *showHeaderView;
@property (strong, nonatomic) IBOutlet UILabel *showNumberLabel;
@property (strong, nonatomic) IBOutlet UILabel *showTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *showTimeLabel;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet KATGShowControlsView *controlsView;
@property (strong, nonatomic) KATGShowPreviewCell *previewCell;

- (IBAction)close:(id)sender;


@end
