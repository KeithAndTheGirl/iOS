//
//  KATGUtil.m
//  KATG
//
//  Created by Nicolas Rostov on 24.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import "KATGUtil.h"

@implementation KATGUtil

+(BOOL)validString:(NSString*)string {
    return [string isKindOfClass:[NSString class]] && [string length] > 0;
}

+(void)setCookieWithName:(NSString*)name value:(NSString*)value forURL:(NSURL*)url {
    if(![KATGUtil validString:name] || ![KATGUtil validString:value] || ![KATGUtil validString:[url absoluteString]])
        return;
    NSDictionary *cookieData = @{NSHTTPCookieName: name,
                                 NSHTTPCookieValue: value,
                                 NSHTTPCookieDomain: [url host],
                                 NSHTTPCookieOriginURL: [url absoluteString],
                                 NSHTTPCookiePath: @"/",
                                 NSHTTPCookieVersion: @"0",
                                 NSHTTPCookieExpires: [[NSDate date] dateByAddingTimeInterval:2629743]};
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieData];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
}

@end
