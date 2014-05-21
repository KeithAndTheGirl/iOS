//
//  KATGURLProtocol.h
//  KATG
//
//  Created by Nicolas Rostov on 12.05.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KATGURLProtocol : NSURLProtocol

+ (void) register;
+ (void) injectURL:(NSString*) urlString cookie:(NSString*)cookie;
+ (NSString*) errorForUrlString:(NSString*)urlString;

@end
