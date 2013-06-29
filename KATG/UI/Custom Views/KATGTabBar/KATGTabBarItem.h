//
//  KATGTabBarItem.h
//  KATG
//
//  Created by Timothy Donnelly on 11/5/12.
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

// Abstract class providing base functionality for KATGTabBarItems

#import <Foundation/Foundation.h>

@class KATGTabBar, KATGTabBarItem;

@protocol KATGTabBarItemDelegate <NSObject>
- (void)tabBarItemDidUpdate:(KATGTabBarItem *)item;
@end

@interface KATGTabBarItem : NSObject

@property (weak, nonatomic) KATGTabBar<KATGTabBarItemDelegate> *tabBar;
@property (nonatomic, readonly) UIView *view;
@property (nonatomic, readonly) CGFloat width;

- (void)performLayout;

@end
