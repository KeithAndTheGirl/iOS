//
//  KATGAppDelegate.m
//  KATG
//
//  Created by Doug Russell on 8/26/12.
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

#import "KATGAppDelegate.h"
#import "KATGAudioSessionManager.h"
#import "KATGMainViewController.h"
#import "UIColor+KATGColors.h"
#import "KATGPushRegistration.h"
#import "KATGWelcomeViewController.h"


#import "KATGSeriesViewController.h"

@protocol KATGNavBar7 <NSObject>

- (void)setTintColor:(UIColor *)color;

@end

@interface KATGAppDelegate ()
- (void)setupAppearance;
@end

@implementation KATGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight takeOff:@"1793cbe2-d3b6-47a5-8122-d7ee9309d4eb"];

	KATGConfigureAudioSessionState(KATGAudioSessionStateAmbient);
    
    [self setupAppearance];
    
	CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
	});
	
	return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	KATGPushRegistration *registration = [KATGPushRegistration sharedInstance];
	registration.deviceToken = deviceToken;
	[registration sendToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	// TODO: Show alert
}

- (void)setupAppearance
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.tabBar.frame = CGRectMake(0, self.tabBar.frame.origin.y-7, self.tabBar.frame.size.width, 56);
    [(UIView*)self.tabBar.subviews[0] setFrame:CGRectMake(0, 0, self.tabBar.frame.size.width, 56)];
    
    UITabBarItem *item0 = [self.tabBar.items objectAtIndex:0];
    item0.image = [[UIImage imageNamed:@"Episodes"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item0.selectedImage = [[UIImage imageNamed:@"EpisodesOn"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item0 setTitlePositionAdjustment:UIOffsetMake(0, -6)];
    
    UITabBarItem *item1 = [self.tabBar.items objectAtIndex:1];
    item1.image = [[UIImage imageNamed:@"Live"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item1.selectedImage = [[UIImage imageNamed:@"LiveOn"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item1 setTitlePositionAdjustment:UIOffsetMake(0, -6)];
    
    UITabBarItem *item2 = [self.tabBar.items objectAtIndex:2];
    item2.image = [[UIImage imageNamed:@"Schedule"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item2.selectedImage = [[UIImage imageNamed:@"ScheduleOn"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item2 setTitlePositionAdjustment:UIOffsetMake(0, -6)];
    
    UITabBarItem *item3 = [self.tabBar.items objectAtIndex:3];
    item3.image = [[UIImage imageNamed:@"Youtube"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item3.selectedImage = [[UIImage imageNamed:@"YoutubeOn"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item3 setTitlePositionAdjustment:UIOffsetMake(0, -6)];
    
    UITabBarItem *item4 = [self.tabBar.items objectAtIndex:4];
    item4.image = [[UIImage imageNamed:@"About"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item4.selectedImage = [[UIImage imageNamed:@"AboutOn"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item4 setTitlePositionAdjustment:UIOffsetMake(0, -6)];
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    BOOL shown = [[[NSUserDefaults standardUserDefaults] valueForKey:@"welcome_shown"] boolValue];
    if(!shown) {
        KATGWelcomeViewController *welcomeController = [[KATGWelcomeViewController alloc] initWithNibName:@"KATGWelcomeViewController" bundle:nil];
        welcomeController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.window.rootViewController presentViewController:welcomeController animated:NO completion:^{
            [[NSUserDefaults standardUserDefaults] setValue:@YES forKey:@"welcome_shown"];
        }];
    }
}

@end
