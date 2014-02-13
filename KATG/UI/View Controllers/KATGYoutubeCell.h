//
//  KATGYoutubeCell.h
//  KATG
//
//  Created by Nicolas Rostov on 12/9/13.
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

extern NSString *const kKATGYoutubeTableViewCellIdentifier;

@interface KATGYoutubeCell : UICollectionViewCell

@property (nonatomic, weak) UIViewController *hostController;
@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) UIView *spinnerView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

-(void)reload;

-(void)willShow;
-(void)willHide;

@end
