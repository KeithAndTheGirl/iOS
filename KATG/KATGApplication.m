//
//  KATGApplication.m
//  KATG
//
//  Created by Nicolas Rostov on 31.12.13.
//  Copyright (c) 2013 Doug Russell. All rights reserved.
//

#import "KATGApplication.h"



@implementation KATGApplication

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
        case UIEventSubtypeRemoteControlPause:
        case UIEventSubtypeRemoteControlStop:
        case UIEventSubtypeRemoteControlNextTrack:
        case UIEventSubtypeRemoteControlPreviousTrack:
            [[NSNotificationCenter defaultCenter] postNotificationName:remoteControlButtonTapped
                                                                object:event];
        default:
            break;
    }
}

@end
