//
//  KATGAudioDownloadManager.h
//  KATG
//
//  Created by Nicolas Rostov on 28.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KATGShow, KATGGuest;

@protocol KATGDownloadToken <NSObject>
@property (nonatomic) CGFloat progress;
@property (copy, nonatomic) void (^progressBlock)(CGFloat progress);
@property (copy, nonatomic) void (^completionBlock)(NSError *error);
- (BOOL)isCancelled;
- (void)cancel;
@end

@interface KATGAudioDownloadManager : NSObject

+ (KATGAudioDownloadManager *)sharedManager;

- (id<KATGDownloadToken>)activeEpisodeAudioDownload:(KATGShow *)show;

- (id<KATGDownloadToken>)downloadEpisodeAudio:(KATGShow *)show progress:(void (^)(CGFloat progress))progress completion:(void (^)(NSError *error))completion;

- (void)removeDownloadedEpisodeAudio:(KATGShow *)show;

@end
