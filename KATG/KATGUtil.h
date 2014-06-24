//
//  KATGUtil.h
//  KATG
//
//  Created by Nicolas Rostov on 24.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KATGUtil : NSObject

+(void)setCookieWithName:(NSString*)name value:(NSString*)value forURL:(NSURL*)url;

@end
