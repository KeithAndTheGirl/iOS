//
//  KATGScheduleCell.h
//  KATG
//
//  Created by Timothy Donnelly on 12/8/12.
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

#import <UIKit/UIKit.h>
#import "KATGMainViewController.h"

extern NSString *const kKATGScheduleItemTableViewCellIdentifier;

@interface KATGScheduleCell : UICollectionViewCell

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, assign) KATGMainViewController *controller;

-(void)willShow;
-(void)willHide;
-(void)refreshTable;

@end
