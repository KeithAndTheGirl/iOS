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
	NSString *mediaURL = show.media_url;
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
    NSString *mediaURL = show.media_url;
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
		[op setDownloadProgressBlock:^(NSUInteger totalBytesRead, NSUInteger totalBytesExpectedToRead) {
			CGFloat value = (CGFloat)totalBytesRead/(CGFloat)totalBytesExpectedToRead;
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
    
    self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];
    
	EpisodeAudioLog(@"Download %@", show.media_url);
	NSNumber *episodeID = show.episode_id;
	NSURL *url = [NSURL URLWithString:show.media_url];
	NSParameterAssert(episodeID);
	NSURL *fileURL = [[self fileURLForEpisodeID:episodeID] URLByAppendingPathExtension:[url pathExtension]];
	void (^finishWithError)(NSError *) = ^(NSError *error) {
		[token callCompletionBlockWithError:error];
		[self.urlToTokenMap removeObjectForKey:url];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
            self.bgTask = UIBackgroundTaskInvalid;
        });
	};
    void (^success)() = ^() {
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication} ofItemAtPath:[fileURL path] error:nil];
        NSManagedObjectContext *context = [[KATGDataStore sharedStore] childContext];
        NSParameterAssert(context);
        [context performBlock:^{
            KATGShow *fetchedShow = [[KATGDataStore sharedStore] fetchShowWithID:episodeID context:context];
            if (fetchedShow) {
                fetchedShow.downloaded = @YES;
                fetchedShow.file_url = [fileURL path];
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
    KATGDownloadOperation *op = [self downloadOperationWithUrl:url fileURL:fileURL progress:progress success:success failure:finishWithError];
	token = [[KATGDownloadToken alloc] initWithOperation:op];
	NSParameterAssert(token);
	token.progressBlock = progress;
	token.completionBlock = completion;
	self.urlToTokenMap[url] = token;
	[self.networkQueue addOperation:op];
	return token;
}

- (void)removeDownloadedEpisodeAudio:(KATGShow *)show {
    if (show.file_url) {
        [[NSFileManager defaultManager] removeItemAtPath:show.file_url error:nil];
        show.downloaded = @NO;
        show.file_url = nil;
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

- (NSURL *)fileURLForEpisodeID:(NSNumber *)episodeID {
	NSParameterAssert(episodeID);
	NSString *fileName = [NSString stringWithFormat:@"%@", episodeID];
	NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
	url = [url URLByAppendingPathComponent:@"Media"];
	BOOL isDir;
	if (![[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDir]) {
		NSError *error;
		if (![[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:NO attributes:nil error:nil])
		{
			NSLog(@"%@", error);
			return nil;
		}
	}
	else {
		NSParameterAssert(isDir);
	}
	url = [url URLByAppendingPathComponent:fileName];
	return url;
}

@end
