//
//  KATGSeries.h
//  KATG
//
//  Created by Nicolas Rostov on 26.03.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSManagedObject+ESObject.h"

extern NSString *const KATGSeriesIDAttributeName;
extern NSString *const KATGSeriesSortAttributeName;

@interface KATGSeries : NSManagedObject

@property (nonatomic, retain) NSNumber * series_id;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * prefix;
@property (nonatomic, retain) NSNumber * vip_status;
@property (nonatomic, retain) NSNumber * sort_order;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * cover_image_url;
@property (nonatomic, retain) NSString * forum_url;
@property (nonatomic, retain) NSString * preview_url;
@property (nonatomic, retain) NSNumber * episode_count;
@property (nonatomic, retain) NSNumber * episode_number_max;

+ (NSNumber *)seriesIDForShowDictionary:(NSDictionary *)showDictionary;
+ (NSString *)katg_entityName;

@end
