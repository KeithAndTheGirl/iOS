//
//  KATGSeries.m
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

#import "KATGSeries.h"

NSString *const KATGSeriesIDAttributeName = @"series_id";
NSString *const KATGSeriesSortAttributeName = @"sort_order";

@implementation KATGSeries

@dynamic series_id;
@dynamic title;
@dynamic desc;
@dynamic forum_url;
@dynamic cover_image_url;
@dynamic preview_url;
@dynamic prefix;
@dynamic vip_status;
@dynamic sort_order;
@dynamic episode_count;
@dynamic episode_number_max;

+ (NSNumber *)seriesIDForShowDictionary:(NSDictionary *)showDictionary
{
	return @([showDictionary[@"ShowNameId"] integerValue]);
}

+ (NSString *)katg_entityName
{
	return @"Series";
}

+ (void)initialize
{
	if (self == [KATGSeries class])
	{
		ESObjectMap *map = [KATGSeries objectMap];
        [map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"ShowNameId" outputKey:@"series_id" transformBlock:^id(id<ESObject> object, id inputValue) {
			return @([inputValue intValue]);
		}]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"Name" outputKey:@"title"]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"Description" outputKey:@"desc"]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"ForumUrl" outputKey:@"forum_url"]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"PreviewUrl" outputKey:@"preview_url"]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"CoverImageUrl" outputKey:@"cover_image_url"]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"Prefix" outputKey:@"prefix"]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"VIP" outputKey:@"vip_status" transformBlock:^id(id<ESObject> object, id inputValue) {
			return @([inputValue boolValue]);
		}]];
        [map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"SortOrder" outputKey:@"sort_order" transformBlock:^id(id<ESObject> object, id inputValue) {
			return @([inputValue integerValue]);
		}]];
        [map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"EpisodeCount" outputKey:@"episode_count" transformBlock:^id(id<ESObject> object, id inputValue) {
			return @([inputValue integerValue]);
		}]];
        [map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"EpisodeNumberMax" outputKey:@"episode_number_max" transformBlock:^id(id<ESObject> object, id inputValue) {
			return @([inputValue integerValue]);
		}]];
	}
}

@end
