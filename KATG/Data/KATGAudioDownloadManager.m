//
//  KATGAudioDownloadManager.m
//  KATG
//
//  Created by Nicolas Rostov on 28.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGAudioDownloadManager.h"
#import "KATGShow.h"
#import "KATGDownloadOperation.h"
#import "KATGDownloadToken.h"
#import "KATGUtil.h"

#if DEBUG
#define EpisodeAudioLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define EpisodeAudioLog(fmt, ...)
#endif //DEBUG

@interface KATGAudioDownloadManager ()

@property (nonatomic) NSMutableDictionary *urlToTokenMap;
@property (nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic) NSOperationQueue *networkQueue;

@end

@implementation KATGAudioDownloadManager

+ (KATGAudioDownloadManager *)sharedManager {
	static KATGAudioDownloadManager *sharedManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManager = [[self class] new];
	});
	return sharedManager;
}


- (instancetype)init {
	self = [super init];
	if (self) {
		_urlToTokenMap = [NSMutableDictionary new];
        self.bgTask = UIBackgroundTaskInvalid;
        
		// Build queues for network and core data operations.
		_networkQueue = [NSOperationQueue new];
		[_networkQueue setMaxConcurrentOperationCount:10];
    }
    return self;
}

- (id<KATGDownloadToken>)activeEpisodeAudioDownload:(KATGShow *)show {
	NSString *mediaURL = [show.media_url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	EpisodeAudioLog(@"Check for download of %@", show.media_url);
	if (mediaURL == nil)
	{
		NSParameterAssert(NO);
		return nil;
	}
	NSURL *url = [NSURL URLWithString:mediaURL];
	if (url == nil)
	{
		NSParameterAssert(NO);
		return nil;
	}
	KATGDownloadToken *token = self.urlToTokenMap[url];
	return token;
}

-(id<KATGDownloadToken>)tokenForShow:(KATGShow*)show {
	NSString *mediaURL = [show.media_url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (mediaURL == nil) {
		NSParameterAssert(NO);
		return nil;
	}
	NSURL *url = [NSURL URLWithString:mediaURL];
	if (url == nil) {
		NSParameterAssert(NO);
		return nil;
	}
	return self.urlToTokenMap[url];
}

- (KATGDownloadOperation *)downloadOperationWithUrl:(NSURL*)url
                                            fileURL:(NSURL*)fileURL
                                           progress:(void (^)(CGFloat progress))progress
                                            success:(void(^)())success
                                            failure:(void(^)(NSError*))failure
                                        autoRetryOf:(int)timesToRetry retryInterval:(int)intervalInSeconds {
    
    void (^retryBlock)(NSError *) = ^(NSError *error) {
        int retryCount = timesToRetry;
        if (retryCount > 0 && self.urlToTokenMap[url] != nil) {
            EpisodeAudioLog(@"AutoRetry: Request failed: %@, retry begining...", error.localizedDescription);
            
            void (^addRetryOperation)() = ^{
                KATGDownloadOperation *retryOperation = [self downloadOperationWithUrl:url fileURL:fileURL progress:progress success:success failure:failure autoRetryOf:retryCount-1 retryInterval:intervalInSeconds];
                [self.networkQueue addOperation:retryOperation];
                KATGDownloadToken *token = self.urlToTokenMap[url];
                if (token) {
                    [token cancel];
                    token.op = retryOperation;
                }
            };
            if (intervalInSeconds > 0) {
                EpisodeAudioLog(@"AutoRetry: Delaying retry for %d seconds... timesToRetry: %i", intervalInSeconds, timesToRetry);
                dispatch_time_t delay = dispatch_time(0, (int64_t)(intervalInSeconds * NSEC_PER_SEC));
                dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                    addRetryOperation();
                });
            } else {
                addRetryOperation();
            }
        } else {
            EpisodeAudioLog(@"AutoRetry: Request failed: %@, no more retries allowed! executing supplied failure block...", error.localizedDescription);
            failure(error);
            EpisodeAudioLog(@"AutoRetry: done.");
        }
    };
    
    KATGDownloadOperation *operation = [self downloadOperationWithUrl:url fileURL:fileURL progress:progress success:^{
        EpisodeAudioLog(@"AutoRetry: success, running success block...");
        success();
        EpisodeAudioLog(@"AutoRetry: done.");
    } failure:retryBlock];
    
    return operation;
}

-(KATGDownloadOperation*)downloadOperationWithUrl:(NSURL*)url
                                          fileURL:fileURL
                                         progress:(void (^)(CGFloat progress))progress
                                          success:(void(^)())success
                                          failure:(void(^)(NSError*))failure {
    
	KATGDownloadOperation *op = [KATGDownloadOperation newDownloadOperationWithRemoteURL:url fileURL:fileURL completion:^(ESHTTPOperation *op) {
		if (op.error) {
			failure(op.error);
		}
		else {
			success();
		}
	}];
    if (progress) {
        __block int downloadedSize = 0;
        if ([fileURL checkResourceIsReachableAndReturnError:nil]) {
            NSNumber *sizeObject;
            NSError *error;
            if ([fileURL getResourceValue:&sizeObject forKey:NSURLFileSizeKey error:&error]) {
                downloadedSize = [sizeObject intValue];
            }
        }
		[op setDownloadProgressBlock:^(NSUInteger totalBytesRead, NSUInteger totalBytesExpectedToRead) {
			CGFloat value = ((CGFloat)totalBytesRead + downloadedSize)/((CGFloat)totalBytesExpectedToRead + downloadedSize);
			value = floorf(value * 100.0f) / 100.0f;
			progress(value);
		}];
	}
    return op;
}

- (id<KATGDownloadToken>)downloadEpisodeAudio:(KATGShow *)show
                                     progress:(void (^)(CGFloat progress))progress
                                   completion:(void (^)(NSError *error))completion {
	__block KATGDownloadToken *token = [self tokenForShow:show];
	if (token) {
		token.progressBlock = progress;
		token.completionBlock = completion;
		EpisodeAudioLog(@"Already downloading %@", show.media_url);
		return token;
	}
    
    if(self.bgTask == UIBackgroundTaskInvalid)
        self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
            self.bgTask = UIBackgroundTaskInvalid;
        }];
    
	EpisodeAudioLog(@"Download %@", show.media_url);
	NSNumber *episodeID = show.episode_id;
	NSString *mediaURL = [show.media_url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSURL *url = [NSURL URLWithString:mediaURL];
	NSParameterAssert(episodeID);
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [KATGUtil setCookieWithName:KATG_PLAYBACK_UID value:[[def valueForKey:KATG_PLAYBACK_UID] stringValue]  forURL:url];
    [KATGUtil setCookieWithName:KATG_PLAYBACK_KEY value:[def valueForKey:KATG_PLAYBACK_KEY]  forURL:url];
    
	void (^finishWithError)(NSError *) = ^(NSError *error) {
		[token callCompletionBlockWithError:error];
		[self.urlToTokenMap removeObjectForKey:url];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
            self.bgTask = UIBackgroundTaskInvalid;
        });
	};
    void (^success)() = ^() {
        NSManagedObjectContext *context = [[KATGDataStore sharedStore] childContext];
        NSParameterAssert(context);
        [context performBlock:^{
            KATGShow *fetchedShow = [[KATGDataStore sharedStore] fetchShowWithID:episodeID context:context];
            if (fetchedShow) {
                fetchedShow.downloaded = @YES;
                [[KATGDataStore sharedStore] saveChildContext:context completion:^(NSError *saveError) {
                    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
                        if (saveError) {
                            EpisodeAudioLog(@"Core Data Error %@", saveError);
                        }
                        finishWithError(saveError);
                    });
                }];
            }
        }];
    };
    
    [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication} ofItemAtPath:[show getFilePath] error:nil];
    NSManagedObjectContext *context = [[KATGDataStore sharedStore] childContext];
    NSParameterAssert(context);
    [context performBlock:^{
        KATGShow *fetchedShow = [[KATGDataStore sharedStore] fetchShowWithID:episodeID context:context];
        if (fetchedShow) {
            [[KATGDataStore sharedStore] saveChildContext:context completion:nil];
        }
    }];
    
    NSURL *fileUrl = [NSURL fileURLWithPath:[show getFilePath]];
    KATGDownloadOperation *op = [self downloadOperationWithUrl:url fileURL:fileUrl progress:progress success:success failure:finishWithError autoRetryOf:15 retryInterval:10];
    [op setResponseBlock:^(NSURLResponse *response) {
        int downloadedSize = 0;
        if ([fileUrl checkResourceIsReachableAndReturnError:nil]) {
            NSNumber *sizeObject;
            NSError *error;
            if ([fileUrl getResourceValue:&sizeObject forKey:NSURLFileSizeKey error:&error]) {
                downloadedSize = [sizeObject intValue];
            }
        }
        show.fileSize = @(downloadedSize+response.expectedContentLength);
    }];
	token = [[KATGDownloadToken alloc] initWithOperation:op];
	NSParameterAssert(token);
	token.progressBlock = progress;
	token.completionBlock = completion;
	self.urlToTokenMap[url] = token;
	[self.networkQueue addOperation:op];
	return token;
}

-(void)cancelDownloadToken:(id<KATGDownloadToken>)token {
    [token cancel];
    NSArray *keys = [self.urlToTokenMap allKeysForObject:token];
    [self.urlToTokenMap removeObjectsForKeys:keys];
}

- (void)removeDownloadedEpisodeAudio:(KATGShow *)show {
    NSString *filePath = [show getFilePath];
    if (filePath) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        show.downloaded = @NO;
        [[KATGDataStore sharedStore] saveChildContext:[[KATGDataStore sharedStore] childContext] completion:^(NSError *saveError) {
            CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
                if (saveError)
                {
                    EpisodeAudioLog(@"Core Data Error %@", saveError);
                }
            });
        }];
    }
}

@end
