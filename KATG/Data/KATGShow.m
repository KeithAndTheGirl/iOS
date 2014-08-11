//
//  KATGShow.m
//  KATG
//
//  Created by Timothy Donnelly on 12/6/12.
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

#import "KATGShow.h"
#import "KATGGuest.h"
#import "KATGImage.h"

NSString *const KATGShowEpisodeIDAttributeName = @"episode_id";

@implementation KATGShow
@dynamic title;
@dynamic episode_id;
@dynamic series_id;
@dynamic desc;
@dynamic forum_url;
@dynamic number;
@dynamic timestamp;
@dynamic access;
@dynamic guests;
@dynamic images;
@dynamic media_url;
@dynamic downloaded;
@dynamic file_url;
@dynamic fileSize;
@dynamic lastPlaybackTime;
@dynamic duration;
@dynamic lastListenedTime;
@dynamic preview_url;
@dynamic video_file_url;
@dynamic video_thumbnail_url;

-(NSNumber*)lastPlaybackTime {
    NSString *key = [NSString stringWithFormat:@"lastPlaybackTime-%@", self.episode_id];
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
//    NSLog(@"Return lastPlaybackTime %@ for episode %@", value, self.episode_id);
    return value;
}

-(void)setLastPlaybackTime:(NSNumber *)lastPlaybackTime {
//    NSLog(@"Set lastPlaybackTime %@ for episode %@", lastPlaybackTime, self.episode_id);
    NSString *key = [NSString stringWithFormat:@"lastPlaybackTime-%@", self.episode_id];
    [[NSUserDefaults standardUserDefaults] setObject:lastPlaybackTime forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSNumber*)duration {
    NSString *key = [NSString stringWithFormat:@"duration-%@", self.episode_id];
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
//    NSLog(@"Return Duration %@ for episode %@", value, self.episode_id);
    return value;
}

-(void)setDuration:(NSNumber *)duration {
//    NSLog(@"Set Duration %@ for episode %@", duration, self.episode_id);
    NSString *key = [NSString stringWithFormat:@"duration-%@", self.episode_id];
    [[NSUserDefaults standardUserDefaults] setObject:duration forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSNumber*)fileSize {
    NSString *key = [NSString stringWithFormat:@"fileSize-%@", self.episode_id];
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    //    NSLog(@"Return fileSize %@ for episode %@", value, self.episode_id);
    return value;
}

-(void)setFileSize:(NSNumber *)fileSize {
    //    NSLog(@"Set fileSize %@ for episode %@", duration, self.episode_id);
    NSString *key = [NSString stringWithFormat:@"fileSize-%@", self.episode_id];
    [[NSUserDefaults standardUserDefaults] setObject:fileSize forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSDate*)lastListenedTime {
    NSString *key = [NSString stringWithFormat:@"lastListenedTime-%@", self.episode_id];
    NSDate *value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    if(!value)
        value = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    return value;
}

-(void)setLastListenedTime:(NSDate *)time {
    NSString *key = [NSString stringWithFormat:@"lastListenedTime-%@", self.episode_id];
    [[NSUserDefaults standardUserDefaults] setObject:time forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSNumber *)episodeIDForShowDictionary:(NSDictionary *)showDictionary
{
	return @([showDictionary[@"ShowId"] integerValue]);
}

+ (NSArray *)guestDictionariesForShowDictionary:(NSDictionary *)showDictionary
{
	return showDictionary[@"Guests"];
}

+ (NSString *)katg_entityName
{
	return @"Show";
}

+ (void)initialize
{
	if (self == [KATGShow class])
	{
		ESObjectMap *map = [KATGShow objectMap];
        [map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"ShowNameId" outputKey:@"series_id" transformBlock:^id(id<ESObject> object, id inputValue) {
			return @([inputValue intValue]);
		}]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"Title" outputKey:@"title"]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"Description" outputKey:@"desc"]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"Number" outputKey:@"number" transformBlock:^id(id<ESObject> object, id inputValue) {
			return @([inputValue integerValue]);
		}]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"ShowId" outputKey:@"episode_id" transformBlock:^id(id<ESObject> object, id inputValue) {
			return @([inputValue integerValue]);
		}]];
		[map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"FileUrl" outputKey:@"media_url"]];
		[map addPropertyMap:[ESEpochDatePropertyMap newPropertyMapWithInputKey:@"Timestamp" outputKey:@"timestamp"]];
        [map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"preview_url" outputKey:@"preview_url"]];
        [map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"VideoFileUrl" outputKey:@"video_file_url"]];
        [map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"VideoThumbnailUrl" outputKey:@"video_thumbnail_url"]];
        [map addPropertyMap:[ESPropertyMap newPropertyMapWithInputKey:@"Public" outputKey:@"access" transformBlock:^id(id<ESObject> object, id inputValue) {
			return @([inputValue boolValue]);
		}]];
	}
}

- (NSArray *)sortedGuests
{
	return [[self.guests allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
}

- (NSString *)formattedTimestamp
{
	NSParameterAssert([NSThread isMainThread]);
	static NSDateFormatter *formatter = nil;
	if (formatter == nil)
	{
		formatter = [NSDateFormatter new];
		[formatter setDateFormat:@"MMM d, yyyy"];
	}
	return [formatter stringFromDate:self.timestamp];
}

- (KATGShowObjectStatus)showStatusBasedOnNotification:(NSNotification *)note checkRelationships:(bool)checkRelationships
{
	NSParameterAssert([[note object] isEqual:[self managedObjectContext]]);
	NSDictionary *userInfo = [note userInfo];
	if (userInfo[NSInvalidatedAllObjectsKey])
	{
		return KATGShowObjectStatusAllInvalidated;
	}
	NSSet *deletedObject = userInfo[NSDeletedObjectsKey];
	KATGShowObjectStatus status = 0;
	if ([deletedObject containsObject:self])
	{
		status |= KATGShowObjectStatusShowDeleted;
	}
	else
	{
		if (checkRelationships)
		{
			if ([deletedObject intersectsSet:self.images])
			{
				status |= KATGShowObjectStatusImagesDeleted;
			}
			if ([deletedObject intersectsSet:self.guests])
			{
				status |= KATGShowObjectStatusGuestsDeleted;
			}
		}
		
		NSSet *refreshedObjects = userInfo[NSRefreshedObjectsKey];
		NSSet *updatedObjects = userInfo[NSUpdatedObjectsKey];
		NSSet *invalidatedObjects = userInfo[NSInvalidatedObjectsKey];
		NSMutableSet *changedObjects = [NSMutableSet setWithCapacity:[refreshedObjects count] + [updatedObjects count] + [invalidatedObjects count]];
		NSParameterAssert(changedObjects);
		if (refreshedObjects)
		{
			[changedObjects unionSet:refreshedObjects];
		}
		if (updatedObjects)
		{
			[changedObjects unionSet:updatedObjects];
		}
		if (invalidatedObjects)
		{
			[changedObjects unionSet:invalidatedObjects];
		}
		if ([changedObjects containsObject:self])
		{
			status |= KATGShowObjectStatusShowReload;
		}
		if (checkRelationships)
		{
			if ([changedObjects intersectsSet:self.images])
			{
				status |= KATGShowObjectStatusImagesReload;
			}
			if ([changedObjects intersectsSet:self.guests])
			{
				status |= KATGShowObjectStatusGuestsReload;
			}
		}
		
		NSSet *insertedObjects = userInfo[NSInsertedObjectsKey];
		if ([insertedObjects containsObject:self])
		{
			status |= KATGShowObjectStatusShowInserted;
		}
		if (checkRelationships)
		{
			if ([insertedObjects intersectsSet:self.images])
			{
				status |= KATGShowObjectStatusImagesInserted;
			}
			if ([insertedObjects intersectsSet:self.guests])
			{
				status |= KATGShowObjectStatusGuestsInserted;
			}
		}
	}
	return status;
}

@end
