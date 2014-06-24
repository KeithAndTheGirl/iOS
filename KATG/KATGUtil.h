//
//  KATGUtil.h
//  KATG
//
//  Created by Nicolas Rostov on 24.06.14.
//  Copyright (c) 2014 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KATG_PLAYBACK_KEY @"KatgVip_key"
#define KATG_PLAYBACK_UID @"KatgVip_uid"
#define KATG_EMAIL @"KATG_EMAIL"
#define KATG_PASSWORD @"KATG_PASS"
 
@interface KATGUtil : NSObject

+(void)setCookieWithName:(NSString*)name value:(NSString*)value forURL:(NSURL*)url;

+(void)alertWithTitle:(NSString*)title message:(NSString*)message;

@end
