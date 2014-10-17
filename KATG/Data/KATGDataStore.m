//
//  KATGEpisodeStore.m
//  KATG
//
//  Created by Timothy Donnelly on 12/5/12.
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

#import "KATGDataStore.h"
#import "KATGDataStore_Internal.h"

#import "KATGShow.h"
#import "KATGGuest.h"
#import "KATGImage.h"
#import "KATGScheduledEvent.h"
#import "KATGSeries.h"

#import "ESHTTPOperation.h"
#import "ESJSONOperation.h"

#import "Reachability.h"
#import "KATGReachabilityOperation.h"

#import "NSMutableURLRequest+ESNetworking.h"

#import "AFNetworking.h"

#if DEBUG && 0
#define EventsLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define EventsLog(fmt, ...) 
#endif //DEBUG

#if DEBUG && 0
#define ShowsLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define ShowsLog(fmt, ...) 
#endif //DEBUG

#if DEBUG && 0
#define CoreDataLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define CoreDataLog(fmt, ...) 
#endif //DEBUG

NSString *const kKATGDataStoreIsReachableKey = @"isReachable";

NSString * const KATGDataStoreConnectivityRestoredNotification = @"KATGDataStoreConnectivityRestoredNotification";
NSString * const KATGDataStoreConnectivityFailureNotification = @"KATGDataStoreConnectivityFailureNotification";

NSString *const KATGDataStoreIsShowLiveDidChangeNotification = @"KATGDataStoreIsShowLiveDidChangeNotification";
NSString *const kKATGDataStoreIsShowLiveKey = @"isShowLive";

NSString *const KATGDataStoreEventsDidChangeNotification = @"KATGDataStoreEventsDidChangeNotification";
NSString *const KATGDataStoreShowDidChangeNotification = @"KATGDataStoreShowDidChangeNotification";

@interface KATGDataStore ()

// General Core Data
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSManagedObjectContext *writerContext;
@property (nonatomic) NSManagedObjectContext *readerContext;

// Base URL
@property (nonatomic) NSURL *baseURL;

// Polling timer
@property (nonatomic, strong) NSTimer *timer;

// Reachability
@property (nonatomic) Reachability *reachabilityForConnectionType;
@property (nonatomic, getter=isReachable) BOOL reachable;
@property (nonatomic) KATGReachabilityOperation *reachabilityOp;

//
@property (nonatomic) BOOL live;

@property (nonatomic, strong) NSNumber *lastSeriesID;
@property (nonatomic, strong) NSNumber *lastEpisodeStartNumber;
@property (nonatomic, copy) void (^lastSuccess)();
@property (nonatomic, copy) void (^lastFailure)();

@end

@implementation KATGDataStore

+ (KATGDataStore *)sharedStore
{
	static KATGDataStore *sharedStore = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedStore = [[self class] new];
	});
	return sharedStore;
}

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		[self coreDataInitialize];
		
		// Build queues for network and core data operations.
		_networkQueue = [NSOperationQueue new];
		[_networkQueue setMaxConcurrentOperationCount:10];
		
		_workQueue = [NSOperationQueue new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminate:) name:UIApplicationWillTerminateNotification object:nil];
		
		_baseURL = [NSURL URLWithString:kServerBaseURL];
		
		_reachabilityForConnectionType = [Reachability reachabilityWithHostName:kReachabilityURL];
		NSParameterAssert(_reachabilityForConnectionType);
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:_reachabilityForConnectionType];
		[_reachabilityForConnectionType startNotifier];
		
		[self startPolling];
	}
	return self;
}

#pragma mark - Core Data Stack

- (void)coreDataInitialize
{
	_managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
	
	NSURL *url = [self storeURL];
	
	// nuke the database on every launch
//	[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
	
	NSError *error = nil;
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
	{
		// Error adding persistent store
		[NSException raise:@"Could not add persistent store" format:@"%@", [error localizedDescription]];
	}
	else
	{
		[[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication} ofItemAtPath:[url path] error:nil];
	}
	
	_writerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	_writerContext.persistentStoreCoordinator = _persistentStoreCoordinator;
	
	_readerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	_readerContext.parentContext = _writerContext;
}

- (NSURL *)storeURL
{
	NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
	return [directoryURL URLByAppendingPathComponent:@"katg3.0.0.sqlite"];
}

- (NSManagedObjectContext *)childContext
{
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	context.parentContext = self.readerContext;
	return context;
}

- (void)saveContext:(NSManagedObjectContext *)context completion:(void (^)(NSError *error))completion
{
	CoreDataLog(@"Save Context: %@", context);
	NSError *error;
	if (![context save:&error])
	{
		CoreDataLog(@"Core Data Error: %@", error);
	}
	else
	{
		error = nil;
	}
	if (completion)
	{
		completion(error);
	}
}

- (void)saveChildContext:(NSManagedObjectContext *)context completion:(void (^)(NSError *error))completion
{
	[self saveContext:context completion:^(NSError *childError) {
		if (childError)
		{
			if (completion)
			{
				completion(childError);
			}
		}
		else
		{
			[self.readerContext performBlock:^{
				[self saveContext:self.readerContext completion:^(NSError *readerError) {
					if (readerError)
					{
						if (completion)
						{
							completion(readerError);
						}
					}
					else
					{
						[self.writerContext performBlock:^{
							[self saveContext:self.writerContext completion:^(NSError *writerError) {
								if (completion)
								{
									completion(writerError);
								}
							}];
						}];
					}
				}];
			}];
		}
	}];
}

#pragma mark - 

- (void)willTerminate:(NSNotification *)notification
{
	NSManagedObjectContext *context = self.writerContext;
	[context performBlockAndWait:^{
		[self saveContext:context completion:nil];
	}];
}

#pragma mark - 

- (void)reachabilityChanged:(NSNotification *)note
{
	NSParameterAssert([NSThread isMainThread]);
	NSParameterAssert([[note object] isEqual:self.reachabilityForConnectionType]);
	self.reachable = [self.reachabilityForConnectionType isReachable];
}

+ (BOOL)automaticallyNotifiesObserversOfReachable
{
	return NO;
}

- (void)setReachable:(BOOL)reachable
{
	if (_reachable != reachable)
	{
		[self willChangeValueForKey:kKATGDataStoreIsReachableKey];
		_reachable = reachable;
		[self didChangeValueForKey:kKATGDataStoreIsReachableKey];
	}
}

#pragma mark - Request from server

- (void)startPolling
{
	self.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(pollForData:) userInfo:nil repeats:YES];
	[self.timer fire];
}

- (void)stopPolling
{
	[self.timer invalidate];
	self.timer = nil;
}

- (void)pollForData:(NSTimer *)timer
{
	[self pollForData];
}

- (void)pollForData
{
    [self downloadAllSeries];
	[self downloadEvents];
	[self checkLive];
}

- (void)downloadAllSeries
{
	//	Retrieve list of shows
	NSURL *url = [NSURL URLWithString:kSeriesListURIAddress relativeToURL:self.baseURL];
	NSParameterAssert(url);
	if (![self networkOperationPreflight:url])
	{
		return;
	}
	ShowsLog(@"Download List of Series");
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	ESJSONOperation *op = [ESJSONOperation newJSONOperationWithRequest:request
															   success:^(ESJSONOperation *op, NSArray *JSON) {
                                                                   if(JSON) {
                                                                       NSParameterAssert([JSON isKindOfClass:[NSArray class]]);
                                                                       NSParameterAssert(([JSON count] > 0));
                                                                       if ([JSON count] > 0) {
                                                                           [self processSeriesList:JSON];
                                                                       }
                                                                   }
															   } failure:^(ESJSONOperation *op) {
																   ShowsLog(@"Series List Download Failed %@", op.error);
																   [self handleError:op.error];
															   }];
	[self.networkQueue addOperation:op];
}

- (void)downloadEpisodesForSeriesID:(NSNumber*)seriesID fromEpisodeNumber:(NSNumber*)startNumber success:(void(^)())success failure:(void(^)())failure
{
    self.lastSeriesID = seriesID;
    self.lastEpisodeStartNumber = startNumber;
    self.lastSuccess = success;
    self.lastFailure = failure;
	//	Retrieve list of shows
    NSString *urlString = [NSString stringWithFormat:@"%@?shownameid=%@&number=%@", kShowListURIAddress, seriesID, startNumber];
	NSURL *url = [NSURL URLWithString:urlString relativeToURL:self.baseURL];
	NSParameterAssert(url);
	if (![self networkOperationPreflight:url])
	{
        failure();
		return;
	}
	ShowsLog(@"Download Shows");
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	ESJSONOperation *op = [ESJSONOperation newJSONOperationWithRequest:request
															   success:^(ESJSONOperation *op, NSArray *JSON) {
																   NSParameterAssert([JSON isKindOfClass:[NSArray class]]);
																   NSParameterAssert(([JSON count] > 0));
																   if ([JSON count] > 0)
																   {
																	   [self processEpisodeList:JSON];
                                                                       success();
																   }
															   } failure:^(ESJSONOperation *op) {
																   ShowsLog(@"Shows Download Failed %@", op.error);
																   [self handleError:op.error];
                                                                   failure();
															   }];
	[self.networkQueue addOperation:op];
}

- (void)downloadEpisodeDetails:(NSNumber *)episodeID
{
	if (!episodeID)
	{
		NSParameterAssert(NO);
		return;
	}
	NSURL *url = [NSURL URLWithString:[kServerBaseURL stringByAppendingPathComponent:[NSString stringWithFormat:kShowDetailsURIAddress, episodeID]]];
	if (![self networkOperationPreflight:url])
	{
		return;
	}
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	ESJSONOperation *op = [ESJSONOperation newJSONOperationWithRequest:request
															   success:^(ESJSONOperation *op, NSDictionary *JSON) {
																   NSParameterAssert([JSON isKindOfClass:[NSDictionary class]]);
																   [self processEpisodeDetails:JSON episodeID:episodeID];
															   } failure:^(ESJSONOperation *op) {
																   ShowsLog(@"Shows Details Download Failed %@", op.error);
																   [self handleError:op.error];
															   }];
	[self.networkQueue addOperation:op];
}

- (void)downloadEvents
{
	EventsLog(@"Download Events");
	NSURL *url = [NSURL URLWithString:kUpcomingURIAddress relativeToURL:self.baseURL];
	if (![self networkOperationPreflight:url])
	{
		return;
	}
	id success = ^(ESJSONOperation *op, id JSON) {
		NSParameterAssert([JSON isKindOfClass:[NSDictionary class]]);
		NSParameterAssert(([(NSDictionary *)JSON count] > 0));
		[self processEvents:[(NSDictionary *)JSON objectForKey:@"events"]];
	};
	id failure = ^(ESJSONOperation *op) {
		[self handleError:op.error];
	};
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	NSParameterAssert(request);
	ESJSONOperation *op = [ESJSONOperation newJSONOperationWithRequest:request success:success failure:failure];
	NSParameterAssert(op);
	[self.networkQueue addOperation:op];
}

- (void)handleError:(NSError *)error
{
	NSParameterAssert(error);
	if ([[error domain] isEqualToString:NSURLErrorDomain])
	{
		switch ([error code]) {
			case NSURLErrorNotConnectedToInternet:
			{
				if (self.reachabilityOp)
				{
					return;
				}
				[self stopPolling];
				self.reachabilityOp = [[KATGReachabilityOperation alloc] initWithHost:kReachabilityURL];
				NSParameterAssert(self.reachabilityOp);
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityRestored:) name:kKATGReachabilityIsReachableNotification object:nil];
				// For now, just start the op manually since the network op preflight logic only expects ESHTTPOperation subclasses
				[self.reachabilityOp start];
				[[NSNotificationCenter defaultCenter] postNotificationName:KATGDataStoreConnectivityFailureNotification object:nil];
				break;
			}
			default:
				break;
		}
	}
}

- (void)reachabilityRestored:(NSNotification *)note
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self startPolling];
        [self downloadAllSeries];
		[self downloadEpisodesForSeriesID:self.lastSeriesID fromEpisodeNumber:self.lastEpisodeStartNumber success:self.lastSuccess failure:self.lastFailure];
		[self downloadEvents];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:kKATGReachabilityIsReachableNotification object:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:KATGDataStoreConnectivityRestoredNotification object:nil];
	});
}

- (bool)networkOperationPreflight:(NSURL *)url
{
	for (ESHTTPOperation *operation in [[self.networkQueue operations] copy])
	{
		if ([operation isFinished] || [operation isCancelled])
			continue;
		
		if ([[operation.URL absoluteString] isEqualToString:[url absoluteString]])
		{
			return false;
		}
	}
	return true;
}

#pragma mark - Parse incoming data
- (void)processSeriesList:(NSArray *)series
{
	NSManagedObjectContext *context = [self childContext];
	[context performBlock:^{
		@autoreleasepool {
			for (NSDictionary *seriesDictionary in series) {
                if (!seriesDictionary) {
                    NSParameterAssert(seriesDictionary);
                    continue;
                }
                NSNumber *series_id = [KATGSeries seriesIDForShowDictionary:seriesDictionary];
                KATGSeries *series = [self fetchSeriesWithID:series_id context:context];
                if (!series) {
                    series = [NSEntityDescription insertNewObjectForEntityForName:[KATGSeries katg_entityName] inManagedObjectContext:context];
                }
                NSParameterAssert(series);
                if (series) {
                    [series configureWithDictionary:seriesDictionary];
                }
			}
			[self saveChildContext:context completion:nil];
		}
	}];
}

- (void)processEpisodeList:(NSArray *)shows
{
	NSManagedObjectContext *context = [self childContext];
	[context performBlock:^{
		@autoreleasepool {
			for (NSDictionary *episodeDictionary in shows) {
                if (!episodeDictionary) {
                    NSParameterAssert(episodeDictionary);
                    continue;
                }
                NSNumber *episode_id = [KATGShow episodeIDForShowDictionary:episodeDictionary];
                KATGShow *show = [self fetchShowWithID:episode_id context:context];
                if (!show) {
                    show = [NSEntityDescription insertNewObjectForEntityForName:[KATGShow katg_entityName]
                                                         inManagedObjectContext:context];
                }
                [self insertOrUpdateGuests:show showDictionary:episodeDictionary context:context];
                NSParameterAssert(show);
                if (show) {
                    [show configureWithDictionary:episodeDictionary];
                }
			}
            NSMutableArray *episodeIDs = [NSMutableArray array];
            for(NSDictionary *episodeDictionary in shows)
                [episodeIDs addObject:[KATGShow episodeIDForShowDictionary:episodeDictionary]];
            [self deleteEpisodesWithSeriesID:shows[0][@"ShowNameId"] exceptIDs:episodeIDs context:context];
			ShowsLog(@"Processed %ld show", (long)[shows count]);
			[self saveChildContext:context completion:nil];
		}
	}];
}

- (void)processEpisodeDetails:(NSDictionary *)episodeDetails episodeID:(NSNumber *)episodeID
{
	if (!episodeDetails)
	{
		NSParameterAssert(episodeDetails);
		return;
	}
	if (!episodeID)
	{
		NSParameterAssert(episodeID);
		return;
	}
	NSManagedObjectContext *context = [self childContext];
	[context performBlock:^{
		@autoreleasepool {
			KATGShow *show = [self fetchShowWithID:episodeID context:context];
			if (!show)
			{
				return;
			}
			NSArray *images = episodeDetails[@"images"];
            [self removeImagesForShow:show context:context];
			for (NSDictionary *imageDictionary in images)
			{
				KATGImage *image = [self fetchOrInsertImageWithID:imageDictionary[@"pictureid"] show:show url:imageDictionary[@"media_url"] context:context];
				if (image)
				{
					[image configureWithDictionary:imageDictionary];
				}
			}
			NSString *notes = episodeDetails[@"notes"];
			NSMutableString *noteLines = [NSMutableString new];
			[notes enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
				// Make sure the line isn't just whitespace
				NSMutableString *mutableLine = [line mutableCopy];
				CFStringTrimWhitespace((__bridge CFMutableStringRef)mutableLine);
				if ([mutableLine length])
				{
					[noteLines appendFormat:@" — %@\n\n", line];
				}
			}];
			if ([noteLines length])
			{
				[noteLines deleteCharactersInRange:NSMakeRange([noteLines length] - 1, 1)];
				show.desc = [noteLines copy];
			}
            show.forum_url = episodeDetails[@"forum_url"];
            show.preview_url = episodeDetails[@"preview_url"];
            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:KATGDataStoreShowDidChangeNotification object:nil];
            });
			[self saveChildContext:context completion:nil];
		}
	}];
}

- (void)processEvents:(NSArray *)eventDictionaries
{
	if (![eventDictionaries count]) 
	{
		NSParameterAssert(NO);
		return;
	}
	NSManagedObjectContext *context = [self childContext];
	[context performBlock:^{
		@autoreleasepool {
			NSMutableSet *newEvents = [NSMutableSet new];
			for (NSDictionary *eventDictionary in eventDictionaries)
			{
				KATGScheduledEvent *event = [self fetchOrInsertEventWithID:eventDictionary[@"eventid"] context:context];
				if (event)
				{
					[event configureWithDictionary:eventDictionary];
					if ([event futureTest])
					{
						[newEvents addObject:[event objectID]];
					}
					else
					{
						[context deleteObject:event];
					}
				}
			}
			EventsLog(@"Processed %ld events", (unsigned long)[newEvents count]);
			[self deleteOldEvents:newEvents context:context];
			[self saveChildContext:context completion:^(NSError *error) {
				if (error)
				{
					[self handleError:error];
				}
				else
				{
					CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
						[[NSNotificationCenter defaultCenter] postNotificationName:KATGDataStoreEventsDidChangeNotification object:nil];
					});
				}
			}];
		}
	}];
}

#pragma mark - Series
- (KATGSeries *)fetchSeriesWithID:(NSNumber *)seriesID context:(NSManagedObjectContext *)context
{
	NSParameterAssert(context);
	if (!seriesID)
	{
		NSParameterAssert(seriesID);
		return nil;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	request.fetchLimit = 1;
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGSeries katg_entityName] inManagedObjectContext:context];
	request.entity = entity;
	request.predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", KATGSeriesIDAttributeName, seriesID];
	NSError *error;
	NSArray *result = [context executeFetchRequest:request error:&error];
	if (!result)
	{
		[NSException raise:@"Fetch failed" format:@"%@", [error localizedDescription]];
	}
	NSParameterAssert([result count] < 2);
	return [result lastObject];
}

#pragma mark - Shows

- (NSManagedObjectID *)insertOrUpdateShow:(NSDictionary *)showDictionary context:(NSManagedObjectContext *)context
{
	NSParameterAssert(context);
	if (!showDictionary)
	{
		NSParameterAssert(showDictionary);
		return nil;
	}
	KATGShow *show = [self fetchOrInsertShowWithID:[KATGShow episodeIDForShowDictionary:showDictionary] context:context];
	NSParameterAssert(show);
	if (show)
	{
		[show configureWithDictionary:showDictionary];
		[self insertOrUpdateGuests:show showDictionary:showDictionary context:context];
	}
	return [show objectID];
}

- (KATGShow *)fetchOrInsertShowWithID:(NSNumber *)episodeID context:(NSManagedObjectContext *)context
{
	NSParameterAssert(context);
	if (!episodeID)
	{
		NSParameterAssert(episodeID);
		return nil;
	}
	KATGShow *show = [self fetchShowWithID:episodeID context:context];
	if (!show)
	{
		show = [NSEntityDescription insertNewObjectForEntityForName:[KATGShow katg_entityName] inManagedObjectContext:context];
		show.episode_id = episodeID;
	}
	NSParameterAssert(show);
	return show;
}

- (KATGShow *)fetchShowWithID:(NSNumber *)episodeID context:(NSManagedObjectContext *)context
{
	NSParameterAssert(context);
	if (!episodeID)
	{
		NSParameterAssert(episodeID);
		return nil;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	request.fetchLimit = 1;
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGShow katg_entityName] inManagedObjectContext:context];
	request.entity = entity;
	request.predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", KATGShowEpisodeIDAttributeName, episodeID];
	NSError *error;
	NSArray *result = [context executeFetchRequest:request error:&error];
	if (!result)
	{
		[NSException raise:@"Fetch failed" format:@"%@", [error localizedDescription]];
	}
	NSParameterAssert([result count] < 2);
	return [result lastObject];
}

- (void)deleteEpisodesWithSeriesID:(NSNumber *)seriesID exceptIDs:(NSArray *)currentShowObjectIDs context:(NSManagedObjectContext *)context
{
	NSParameterAssert(currentShowObjectIDs);
	NSParameterAssert(context);
	if (![currentShowObjectIDs count])
	{
		return;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGShow katg_entityName] inManagedObjectContext:context];
	request.entity = entity;
	request.predicate = [NSPredicate predicateWithFormat:@"(%K == %@) and not (%K IN %@)", KATGSeriesIDAttributeName, seriesID, KATGShowEpisodeIDAttributeName, currentShowObjectIDs];
	NSError *error;
	NSArray *result = [context executeFetchRequest:request error:&error];

	NSLog(@"Deleting %ld shows", (long)[result count]);
	for (KATGShow *show in result)
	{
		if (show.file_url)
		{
			[[NSFileManager defaultManager] removeItemAtPath:show.file_url error:nil];
		}
		[context deleteObject:show];
	}
}

#pragma mark - Guests

- (void)insertOrUpdateGuests:(KATGShow *)show showDictionary:(NSDictionary *)showDictionary context:(NSManagedObjectContext *)context
{
	if (!show)
	{
		NSParameterAssert(show);
		return;
	}
	if (!showDictionary)
	{
		NSParameterAssert(showDictionary);
		return;
	}
	NSArray *guests = [KATGShow guestDictionariesForShowDictionary:showDictionary];
	NSParameterAssert(guests);
	for (NSDictionary *guestDict in guests)
	{
		KATGGuest *guest = [self fetchOrInsertGuestWithID:[KATGGuest guestIDForGuestDictionary:guestDict] context:context];
		NSParameterAssert(guest);
		if (guest)
		{
            NSDictionary *imageDictionary = @{@"media_url": guestDict[@"PictureUrlLarge"],
                                              @"description": guestDict[@"Description"],
                                              @"title": guestDict[@"RealName"]};
            
            // This block creates Guest's Image and adds to show images
//            KATGImage *image = [self fetchOrInsertImageWithID: show:show url:imageDictionary[@"media_url"] context:context];
   
            // This block creates Guest's Image, but doesn't add to show images
            NSFetchRequest *request = [NSFetchRequest new];
            request.fetchLimit = 1;
            NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGImage katg_entityName] inManagedObjectContext:context];
            request.entity = entity;
            request.predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", KATGImageMediaURLAttributeName, imageDictionary[@"media_url"]];
            KATGImage *image = [NSEntityDescription insertNewObjectForEntityForName:[KATGImage katg_entityName] inManagedObjectContext:context];
            ////
            if (image)
            {
                [image configureWithDictionary:imageDictionary];
            }
            guest.image = image;
            
			[guest configureWithDictionary:guestDict];
			[guest addShowsObject:show];
			[show addGuestsObject:guest];
		}
	}
}

- (KATGGuest *)fetchOrInsertGuestWithID:(NSNumber *)guestID context:(NSManagedObjectContext *)context
{
	NSParameterAssert(context);
	if (!guestID)
	{
		NSParameterAssert(guestID);
		return nil;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	request.fetchLimit = 1;
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGGuest katg_entityName] inManagedObjectContext:context];
	request.entity = entity;	
	request.predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", KATGGuestGuestIDAttributeName, guestID];
	NSError *error = nil;
	NSArray *result = [context executeFetchRequest:request error:&error];
	if (!result)
	{
		[NSException raise:@"Fetch failed" format:@"%@", [error localizedDescription]];
	}
	if ([result count])
	{
		return result[0];
	}
	// Does not exist, create it
	KATGGuest *guest = [NSEntityDescription insertNewObjectForEntityForName:[KATGGuest katg_entityName] inManagedObjectContext:context];
	guest.guest_id = guestID;
	return guest;
}

#pragma mark - Images

- (void)removeImagesForShow:(KATGShow*)show context:(NSManagedObjectContext *)context {
    for(KATGImage *image in show.images.allObjects)
        [context deleteObject:image];
}

- (KATGImage *)fetchOrInsertImageWithID:(NSString*)pictureID show:(KATGShow *)show url:(NSString *)url context:(NSManagedObjectContext *)context
{
	NSParameterAssert(context);
	if (!show)
	{
		NSParameterAssert(show);
		return nil;
	}
	if (!url)
	{
		NSParameterAssert(url);
		return nil;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	request.fetchLimit = 1;
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGImage katg_entityName] inManagedObjectContext:context];
	request.entity = entity;	
	request.predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", KATGImageMediaIDAttributeName, pictureID];
	NSError *error = nil;
	NSArray *result = [context executeFetchRequest:request error:&error];
	if (!result)
	{
		[NSException raise:@"Fetch failed" format:@"%@", [error localizedDescription]];
	}
	if ([result count])
	{
		return result[0];
	}
	// Does not exist, create it
	KATGImage *image = [NSEntityDescription insertNewObjectForEntityForName:[KATGImage katg_entityName] inManagedObjectContext:context];
	NSParameterAssert(image);
	image.show = show;
    image.pictureid = pictureID;
	[show addImagesObject:image];
	return image;
}

#pragma mark - Events

- (KATGScheduledEvent *)fetchOrInsertEventWithID:(NSString *)eventid context:(NSManagedObjectContext *)context
{
	if (!eventid)
	{
		NSParameterAssert(eventid);
		return nil;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	request.fetchLimit = 1;
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGScheduledEvent katg_entityName] inManagedObjectContext:context];
	request.entity = entity;	
	request.predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", KATGScheduledEventEventIDAttributeName, eventid];
	NSError *error = nil;
	NSArray *result = [context executeFetchRequest:request error:&error];
	if (!result)
	{
		[NSException raise:@"Fetch failed" format:@"%@", [error localizedDescription]];
	}
	if ([result count])
	{
		return result[0];
	}
	// Does not exist, create it
	KATGScheduledEvent *event = [NSEntityDescription insertNewObjectForEntityForName:[KATGScheduledEvent katg_entityName] inManagedObjectContext:context];
	NSParameterAssert(event); 
	event.eventid = eventid;
	return event;
}

- (void)deleteOldEvents:(NSSet *)currentEventsObjectIDs context:(NSManagedObjectContext *)context
{
	NSParameterAssert(currentEventsObjectIDs);
	if (![currentEventsObjectIDs count])
	{
		return;
	}
	NSFetchRequest *request = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[KATGScheduledEvent katg_entityName] inManagedObjectContext:context];
	request.entity = entity;
	request.predicate = [NSPredicate predicateWithFormat:@"NOT (self IN %@)", currentEventsObjectIDs];
	NSError *error;
	NSArray *result = [context executeFetchRequest:request error:&error];
	EventsLog(@"Deleting %ld events", (unsigned long)[result count]);
	for (KATGScheduledEvent *event in result)
	{
		[context deleteObject:event];
	}
}

#pragma mark - Live

// Observable
- (BOOL)isShowLive
{
	return self.live;
}

- (void)setTestLiveMode:(BOOL)value {
    self.live = value;
}

- (void)setLive:(BOOL)live
{
	NSParameterAssert([NSThread isMainThread]);
	if (_live != live)
	{
		[self willChangeValueForKey:kKATGDataStoreIsShowLiveKey];
		_live = live;
		[self didChangeValueForKey:kKATGDataStoreIsShowLiveKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:KATGDataStoreIsShowLiveDidChangeNotification object:nil];
	}
}

- (void)checkLive
{
	// See if show is live
	NSURL *url = [NSURL URLWithString:kLiveShowStatusURIAddress relativeToURL:self.baseURL];
	if (![self networkOperationPreflight:url])
	{
		return;
	}
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	ESJSONOperation *op = [ESJSONOperation newJSONOperationWithRequest:request
															   success:^(ESJSONOperation *op, NSDictionary *JSON) {
																   NSParameterAssert([JSON isKindOfClass:[NSDictionary class]]);
																   BOOL live = [JSON[@"broadcasting"] boolValue];
																   dispatch_async(dispatch_get_main_queue(), ^(void) {
																	   self.live = live;
																   });
															   } failure:^(ESJSONOperation *op) {
																   [self handleError:op.error];
															   }];
	NSParameterAssert(op);
	[self.networkQueue addOperation:op];
}

#pragma mark - Feedback

- (void)submitFeedback:(NSString *)name location:(NSString *)location comment:(NSString *)comment completion:(void (^)(BOOL,NSArray*))completion
{
    comment = [comment stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary: @{@"HiddenVoxbackId" : @"3", @"HiddenMixerCode" : @"IEOSE"}];
    [parameters setObject:comment?comment:@"" forKey:@"Comment"];
    [parameters setObject:name?name:@"" forKey:@"Name"];
    [parameters setObject:location?location:@"" forKey:@"Location"];
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://www.attackwork.com"]];
    [manager POST:@"Voxback/Comment-Form-Iframe.aspx?VoxbackId=3&MixerCode=IEOSE&response-api=yes"
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if(completion) {
                  completion([responseObject[@"error"] boolValue], responseObject[@"response"]);
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"%@", [error description]);
              if(completion) {
                  completion(YES, @[@"Error sending feedback"]);
              }
          }];
}

@end
